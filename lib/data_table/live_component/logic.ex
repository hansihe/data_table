defmodule DataTable.LiveComponent.Logic do
  @moduledoc """
  This module contains all the business logic for the data table.
  All of this is built on top of the `DataDeps` data structure.

  Inputs to the `DataDeps` structure are change tracked, and any
  derived calculations are only executed if any of its predecessors
  are marked as changed. Notably:
  * Inputs `assign_input` are change tracked with equality.
  * Derived computations `assign_derive` are always marked
    as changed when any inputs change.
  This gives us a middle ground between calculating everything on
  every small change vs spending unneeded cycles doing equality checks.
  """

  # For `to_form`
  use Phoenix.LiveComponent

  alias DataTable.Util.DataDeps
  alias DataTable.LiveComponent.Filters

  @doc """
  This should be called once at beginning of the component lifecycle
  to initialize state. `compute/1` MUST be called on the `data_deps`
  after.
  """
  def init(data_deps) do
    data_deps
    |> DataDeps.assign_input(:selection, {:include, %{}})
    |> DataDeps.assign_input(:expanded, %{})
    |> DataDeps.assign_input(:sort, nil)
    |> DataDeps.assign_input(:page, 0)
    |> DataDeps.assign_input(:page_size, 20)
    # TODO this can be preinitialized to prevent update cycle on mount.
    |> DataDeps.assign_input(:dispatched_nav, nil)
  end

  @doc """
  Performs computation of state which has changed.
  """
  def compute(data_deps) do
    data_deps
    # Config phase computes any data which is derived from
    # any "config" component assigns.
    # Expectation is generally that this does not change that
    # often during normal operation.
    |> compute_config_phase()
    # The early NAV phase synchronizes the DataTable state with
    # what is provided by the nav assign input.
    # If input NAV does not differ from internal state, no changes
    # will be marked, which prevents state change loops.
    |> compute_early_nav_phase()
    # The UI phase handles any derived data from UI interactions.
    |> compute_ui_phase()
    # The query phase performs the source query to fetch data
    # the table needs, then computes any state derived from that.
    |> compute_query_phase()
    # The late NAV phase is responsible for dispatching any potential
    # changed NAV state to the user provided NAV state handler.
    |> compute_late_nav_phase()
  end

  defp compute_early_nav_phase(data_deps) do
    data_deps
    # This relies on the fact that this will only be executed when
    # `nav` actually changes.
    # If this was executed every time, then user changes would get
    # overridden.
    |> DataDeps.assign_derive([:nav], [:filter_columns, :dispatched_nav], fn
      data = %{nav: nav} when nav != nil ->
        nav = data.nav

        out = %{}

        out =
          if MapSet.member?(nav.set, :filters) do
            changes = %{
              "filters" =>
                nav.filters
                |> Enum.map(fn {field, op, value} ->
                  %{"field" => field, "op" => op, "value" => value}
                end)
            }

            changeset = Filters.changeset(%Filters{}, data.filter_columns, changes)
            Map.put(out, :filters_changeset, changeset)
          else
            out
          end

        out =
          if MapSet.member?(nav.set, :sort) do
            Map.put(out, :sort, nav.sort)
          else
            out
          end

        out =
          if MapSet.member?(nav.set, :page) do
            Map.put(out, :page, nav.page)
          else
            out
          end

        out

      _ ->
        %{}
    end)
  end

  defp compute_late_nav_phase(data_deps) do
    data_deps
    |> DataDeps.assign_derive(
      [:filters_changeset, :sort, :page],
      [:dispatched_nav, :handle_nav],
      fn data ->
        raw_filters = Ecto.Changeset.apply_changes(data.filters_changeset)

        new_nav = %DataTable.NavState{
          filters:
            Enum.map(raw_filters.filters, fn %{field: field, op: op, value: value} ->
              {field, op, value}
            end),
          sort: data.sort,
          page: data.page
        }

        if new_nav != data.dispatched_nav do
          if data.handle_nav do
            data.handle_nav.(new_nav)
          end

          %{
            dispatched_nav: new_nav
          }
        else
          %{}
        end
      end
    )
  end

  defp compute_config_phase(data_deps) do
    data_deps
    # Callbacks in the `Source` module provides configuration data
    # which a lot of other state in the view is derived from.
    # This config is assumed to be static, and will only be obtained
    # once at the beginning of the view.
    # A source change will trigger changes and recomputations for most
    # other state as well.
    |> DataDeps.assign_derive([:source], fn fields ->
      filterable_columns = DataTable.Source.filterable_fields(fields.source)
      filter_types = DataTable.Source.filter_types(fields.source)
      id_field = DataTable.Source.key(fields.source)

      %{
        id_field: id_field,
        filter_column_order:
          Enum.map(filterable_columns, fn data ->
            Atom.to_string(data.col_id)
          end),
        filter_columns:
          Enum.into(
            Enum.map(filterable_columns, fn data ->
              id_str = Atom.to_string(data.col_id)

              out = %{
                id: id_str,
                name: id_str,
                type_name: data.type,
                validate: filter_types[data.type].validate,
                ops_order:
                  Enum.map(filter_types[data.type].ops, fn {id, _name} ->
                    Atom.to_string(id)
                  end),
                ops:
                  Enum.into(
                    Enum.map(filter_types[data.type].ops, fn {id, name} ->
                      id_str = Atom.to_string(id)

                      out = %{
                        id: id_str,
                        name: name
                      }

                      {id_str, out}
                    end),
                    %{}
                  )
              }

              {id_str, out}
            end),
            %{}
          ),
        filters_fields:
          filterable_columns
          |> Enum.map(fn col ->
            %{
              name: Atom.to_string(col.col_id),
              id_str: Atom.to_string(col.col_id)
            }
          end)
      }
    end)
    # In case of a filter column change, we need to recreate the filter
    # changeset.
    |> DataDeps.assign_derive([:filter_columns], fn fields ->
      # TODO maybe transfer filters?
      filters = %Filters{}
      filters_changeset = Filters.changeset(filters, fields.filter_columns, %{})
      filters_form = Phoenix.Component.to_form(filters_changeset)

      %{
        filters_changeset: filters_changeset,
        filters: filters,
        filters_form: filters_form
      }
    end)
    # `selection_action` is a component assign from the user,
    # We derive data structures which are better suited for rendering.
    |> DataDeps.assign_derive([:selection_action], fn fields ->
      selection_actions =
        if fields[:selection_action] do
          fields.selection_action
          |> Enum.map(fn %{label: label, handle_action: action} -> {label, action} end)
          |> Enum.with_index()
        else
          []
        end

      %{
        can_select: selection_actions != [],
        selection_actions:
          Enum.map(selection_actions, fn {{name, action_fn}, idx} ->
            %{
              label: name,
              action_idx: idx,
              action_fn: action_fn
            }
          end)
      }
    end)
    # Whether a `row_expanded` component assign is present determines
    # if expansion UI will be rendered.
    # We derive state for this.
    |> DataDeps.assign_derive([:row_expanded], fn fields ->
      %{
        can_expand: fields.row_expanded != [],
        row_expanded_slot: fields.row_expanded,
        expanded_fields:
          fields.row_expanded
          |> Enum.map(fn re -> Map.get(re, :fields, []) end)
          |> Enum.concat()
      }
    end)
    # Whether a `row_buttons` component assign is present determines
    # if the buttons row is visible.
    # We derive state for this.
    |> DataDeps.assign_derive([:row_buttons], fn fields ->
      %{
        has_row_buttons:
          fields.row_buttons != nil and
            fields.row_buttons != [],
        row_buttons_slot: fields.row_buttons
      }
    end)
    # We derive a set of columns which are always included in the query.
    # This includes:
    # * Id field
    # * Fields needed for row buttons as these are always visible
    # * Columns manually marked as always columns by component assigns
    |> DataDeps.assign_derive([:row_buttons, :id_field, :always_columns], fn fields ->
      %{
        frame_query_columns:
          fields.row_buttons
          |> Enum.map(fn rb -> Map.get(rb, :fields, []) end)
          |> Enum.concat()
          |> Enum.concat(fields.always_columns)
          |> Enum.concat([fields.id_field])
      }
    end)
    # Derive state from the `col` component assign.
    # This determines which columns are displayable.
    # Derived data includes defaults, field ids, and bidirectional maps.
    |> DataDeps.assign_derive([:col], fn data ->
      fields =
        Enum.map(data.col, fn slot = %{__slot__: :col, fields: fields, name: name} ->
          %{
            id: name,
            name: name,
            columns: fields,
            slot: slot,
            sort_field: Map.get(slot, :sort_field),
            filter_field: Map.get(slot, :filter_field),
            filter_field_op: Map.get(slot, :filter_field_op)
          }
        end)

      %{
        fields: fields,
        default_shown_fields:
          data.col
          |> Enum.map(fn
            %{visible: false} -> []
            %{name: name} -> [name]
          end)
          |> Enum.concat(),
        field_id_by_str_id:
          fields
          |> Enum.map(fn
            %{id: id} when is_atom(id) -> {Atom.to_string(id), id}
            %{id: id} when is_binary(id) -> {id, id}
          end)
          |> Enum.into(%{}),
        field_by_id:
          fields
          |> Enum.map(&{&1.id, &1})
          |> Enum.into(%{})
      }
    end)
  end

  defp compute_query_phase(data_deps) do
    data_deps
    |> DataDeps.assign_derive(
      [
        :source,
        :expanded_fields,
        :shown_fields,
        :fields,
        :frame_query_columns,
        :filters,
        :sort,
        :page,
        :page_size
      ],
      fn data ->
        expanded_columns = MapSet.new(data.expanded_fields)

        columns =
          data.shown_fields
          |> Enum.map(&Enum.find(data.fields, fn f -> f.id == &1 end))
          |> Enum.map(& &1.columns)
          |> Enum.concat()
          |> MapSet.new()
          |> MapSet.union(MapSet.new(data.frame_query_columns))
          |> MapSet.union(expanded_columns)

        filters =
          data.filters.filters
          |> Enum.map(fn f ->
            %{
              field: String.to_existing_atom(f.field),
              op: String.to_existing_atom(f.op),
              value: f.value
            }
          end)

        query_params =
          %DataTable.Source.Query{
            filters: filters,
            sort: data.sort,
            offset: data.page * data.page_size,
            limit: data.page_size,
            fields: columns

            # shown_fields: socket.assigns.shown_fields,
          }

        %{
          results: results,
          total_results: total_results
        } = DataTable.Source.query(data.source, query_params)

        # socket =
        #  if socket.assigns.handle_nav do
        #    if nav != socket.assigns.nav do
        #      socket.assigns.handle_nav.(nav)
        #    end
        #    socket
        #  else
        #    assign(socket, :nav, nav)
        #  end

        %{
          results: results,
          page_results: Enum.count(results),
          total_results: total_results,
          queried_columns: columns
        }
      end
    )
    |> DataDeps.assign_derive(
      [:id_field, :results, :page, :page_size, :total_results, :expanded, :selection],
      fn data ->
        page_idx = data.page
        page_size = data.page_size
        total_results = data.total_results
        max_page = div(total_results + (page_size - 1), page_size) - 1

        %{
          # Data
          rows:
            Enum.map(data.results, fn row ->
              id = row[data.id_field]

              %{
                id: id,
                data: row,
                expanded: Map.has_key?(data.expanded, "#{id}"),
                selected:
                  case data.selection do
                    {:include, %{^id => _}} -> true
                    {:include, %{}} -> false
                    {:exclude, %{^id => _}} -> false
                    {:exclude, %{}} -> true
                  end
              }
            end),

          # Pagination
          page_start_item: min(page_size * page_idx, total_results),
          page_end_item: min(page_size * page_idx + page_size, total_results),
          total_results: total_results,
          page_max: max_page,
          has_prev: page_idx > 0,
          has_next: page_idx < max_page
        }
      end
    )
  end

  defp compute_ui_phase(data_deps) do
    data_deps
    # Reset the shown fields set when defaults change.
    # TODO this is wrong right now, as it does not check for any
    # actual changes to the defaults. Right now shown fields will reset
    # when anything in `col`s change.
    |> DataDeps.assign_derive([:default_shown_fields], fn fields ->
      %{
        shown_fields: MapSet.new(fields.default_shown_fields)
      }
    end)
    # When selection changes, we need to recompute any derived UI
    # state for it.
    |> DataDeps.assign_derive([:selection], fn fields ->
      %{
        has_selection: fields.selection != {:include, %{}},
        header_selection:
          case fields.selection do
            {:include, map} when map_size(map) == 0 -> false
            {:exclude, map} when map_size(map) == 0 -> true
            _ -> :dash
          end
      }
    end)
    |> DataDeps.assign_derive([:fields, :shown_fields, :sort], fn fields ->
      %{
        header_fields:
          fields.fields
          |> Enum.filter(&MapSet.member?(fields.shown_fields, &1.id))
          |> Enum.map(fn field ->
            filter_field = field.filter_field
            filter_field_op = field.filter_field_op
            sort_field = field.sort_field

            %{
              name: field.name,
              can_sort: sort_field != nil,
              sort:
                case fields.sort do
                  {^sort_field, :asc} -> :asc
                  {^sort_field, :desc} -> :desc
                  _ -> nil
                end,
              sort_toggle_id: Atom.to_string(field.sort_field),
              can_filter: filter_field != nil,
              filter_field_id: Atom.to_string(filter_field),
              filter_field_op_id: Atom.to_string(filter_field_op)
            }
          end),
        togglable_fields:
          Enum.map(fields.fields, fn field ->
            {field.name, id_to_string(field.id), MapSet.member?(fields.shown_fields, field.id)}
          end),
        field_slots:
          fields.fields
          |> Enum.filter(&MapSet.member?(fields.shown_fields, &1.id))
          |> Enum.map(& &1.slot)
      }
    end)
    # Apply filters changeset and validate.
    |> DataDeps.assign_derive(
      [:filters_changeset, :filter_column_order, :filter_columns],
      fn fields ->
        changeset = fields.filters_changeset

        changeset =
          if not Enum.empty?(fields.filter_column_order) do
            add_filter_defaults(changeset, fields)
          else
            changeset
          end

        case Ecto.Changeset.apply_action(changeset, :insert) do
          {:ok, data} ->
            %{
              filters: data,
              filters_changeset: changeset,
              filters_form: to_form(changeset)
            }

          {:error, changeset} ->
            %{
              filters_changeset: changeset,
              filters_form: to_form(changeset)
            }
        end
      end
    )
  end

  defp add_filter_defaults(changeset, assigns) do
    data = Ecto.Changeset.apply_changes(changeset)

    first_field = hd(assigns.filter_column_order)
    first_op = hd(assigns.filter_columns[first_field].ops_order)

    changes = %{
      "filters" =>
        Enum.map(data.filters, fn filter ->
          %{
            "field" => filter.field || first_field,
            "op" => filter.op || first_op,
            "value" => filter.value || ""
          }
        end)
    }

    Filters.changeset(changeset, assigns.filter_columns, changes)
  end

  defp id_to_string(id) when is_binary(id), do: id

  def field_by_str_id(str_id, socket) do
    id = Map.fetch!(socket.assigns.field_id_by_str_id, str_id)
    Map.fetch!(socket.assigns.field_by_id, id)
  end

  # # NAV change updates:
  # # 1. nav A, internal A - No dispatch, No update
  # # 2. nav A, internal B - Dispatch, Update
  # # 3. nav nil, internal A - Dispatch, No update

  # # Only dispatch if: nav != nil and nav != dispatched
  # #   On dispatch, set dispatched_nav

  # # Update nav state if present
  # new_nav = assigns[:nav]
  # dispatched_nav = socket.assigns.dispatched_nav
  # # Nav state is only updated if it has changed since the last dispatch.
  # # This prevents a secondary DOM update after the nav state makes the round
  # # trip to the query string.
  # if new_nav != nil and new_nav != dispatched_nav do
  #   nil
  # end
end
