defmodule DataTable.LiveComponent do
  @moduledoc false
  use Phoenix.LiveComponent

  alias __MODULE__.Filters

  defp id_to_string(id) when is_binary(id), do: id

  @impl true
  def render(assigns) do
    assigns.theme.root(assigns)
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    first = socket.assigns[:first] != false

    selection_actions =
      assigns.selection_action
      |> Enum.map(fn %{label: label, handle_action: action} -> {label, action} end)
      |> Enum.with_index()

    # Changable data
    socket =
      assign(socket, %{
        theme: assigns.theme,

        # Selection
        can_select:
          selection_actions != nil and
            selection_actions != [],
        selection_actions:
          Enum.map(selection_actions, fn {{name, action_fn}, idx} ->
            %{
              label: name,
              action_idx: idx,
              action_fn: action_fn
            }
          end),

        # Slots
        can_expand:
          assigns.row_expanded != nil and
            assigns.row_expanded != [],
        row_expanded_slot: assigns.row_expanded,
        has_row_buttons:
          assigns.row_buttons != nil and
            assigns.row_buttons != [],
        row_buttons_slot: assigns.row_buttons
      })

    socket =
      if first do
        # TODO this is shit, should execute on every update
        socket =
          socket
          |> assign_static_data(assigns)

        static = socket.assigns.static

        filters = %Filters{}
        filters_changeset = Filters.changeset(filters, static.filter_columns, %{})
        filters_form = Phoenix.Component.to_form(filters_changeset)

        socket
        |> assign(%{
          id: assigns.id,
          filters_changeset: filters_changeset,
          filters: filters,
          filters_form: filters_form,
          sort: nil,
          page: 0,
          handle_nav: assigns[:handle_nav],
          expanded: %{},
          shown_fields: MapSet.new(static.default_shown_fields),
          selection: {:include, %{}},
          dispatched_nav: nil,
          first: false
        })
        |> assign_base_render_data()
        |> do_query()
      else
        socket
      end

    copy_assigns = Map.take(assigns, [:row_buttons, :row_expanded, :top_right])
    socket = assign(socket, copy_assigns)

    # Update nav state if present
    new_nav = assigns[:nav]
    dispatched_nav = socket.assigns.dispatched_nav
    # Nav state is only updated if it has changed since the last dispatch.
    # This prevents a secondary DOM update after the nav state makes the round
    # trip to the query string.
    socket =
      if new_nav != nil and new_nav != dispatched_nav do
        socket
        |> nav_to_state(new_nav)
        |> do_query()
      else
        socket
      end

    socket = assign_query_render_data(socket)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle-field", %{"field" => field}, socket) do
    field_data = field_by_str_id(field, socket)

    shown_fields =
      if MapSet.member?(socket.assigns.shown_fields, field_data.id) do
        MapSet.delete(socket.assigns.shown_fields, field_data.id)
      else
        MapSet.put(socket.assigns.shown_fields, field_data.id)
      end

    socket =
      socket
      |> assign(:shown_fields, shown_fields)
      |> assign_base_render_data()
      |> do_query()
      |> assign_query_render_data()

    {:noreply, socket}
  end

  def handle_event("cycle-sort", %{"sort-toggle-id" => field_str}, socket) do
    # TODO validate further. Not a security issue, but nice to have.
    field = String.to_existing_atom(field_str)

    socket =
      socket
      |> update(:sort, &cycle_sort(&1, field))
      |> assign_base_render_data()
      |> do_query()
      |> assign_query_render_data()
      |> dispatch_handle_nav()

    {:noreply, socket}
  end

  def handle_event("toggle-expanded", %{"data-id" => data_id}, socket) do
    expanded =
      if Map.has_key?(socket.assigns.expanded, data_id) do
        Map.delete(socket.assigns.expanded, data_id)
      else
        Map.put(socket.assigns.expanded, data_id, true)
      end

    socket =
      socket
      |> assign(:expanded, expanded)
      |> assign_base_render_data()
      |> do_query()
      |> assign_query_render_data()

    {:noreply, socket}
  end

  def handle_event("change-page", %{"page" => page}, socket) do
    socket =
      socket
      |> put_page(page)
      |> assign_base_render_data()
      |> do_query()
      |> assign_query_render_data()
      |> dispatch_handle_nav()

    {:noreply, socket}
  end

  def handle_event("toggle-all", _params, socket) do
    selection =
      case socket.assigns.selection do
        {:include, map} when map_size(map) == 0 -> {:exclude, %{}}
        {:exclude, map} when map_size(map) == 0 -> {:include, %{}}
        _ -> {:exclude, %{}}
      end

    socket =
      socket
      |> assign(:selection, selection)
      |> assign_base_render_data()
      |> do_query()
      |> assign_query_render_data()

    {:noreply, socket}
  end

  def handle_event("toggle-row", %{"id" => row_id}, socket) do
    {row_id, ""} = Integer.parse(row_id)

    selection =
      case socket.assigns.selection do
        {:include, map = %{^row_id => _}} -> {:include, Map.delete(map, row_id)}
        {:include, map} -> {:include, Map.put(map, row_id, nil)}
        {:exclude, map = %{^row_id => _}} -> {:exclude, Map.delete(map, row_id)}
        {:exclude, map} -> {:exclude, Map.put(map, row_id, nil)}
      end

    socket =
      socket
      |> assign(:selection, selection)
      |> assign_base_render_data()
      |> assign_query_render_data()

    {:noreply, socket}
  end

  def handle_event("selection-action", %{"action-idx" => action_idx}, socket) do
    {action_idx, ""} = Integer.parse(action_idx)
    %{action_fn: action_fn} = Enum.fetch!(socket.assigns.selection_actions, action_idx)

    selection = socket.assigns.selection
    action_fn.(selection)

    socket =
      socket
      |> assign_base_render_data()
      |> assign_query_render_data()

    {:noreply, socket}
  end

  def handle_event("filters-change", params, socket) do
    static = socket.assigns.static
    filters_changes = params["filters"] || %{}

    changeset =
      %Filters{}
      |> Filters.changeset(static.filter_columns, filters_changes)

    socket =
      socket
      |> apply_filters_changeset(changeset)
      |> dispatch_handle_nav()

    {:noreply, socket}
  end

  defp make_query_params(socket) do
    static = socket.assigns.static

    expanded_columns =
      if map_size(socket.assigns.expanded) > 0 do
        MapSet.new(static.expanded_fields)
      else
        MapSet.new()
      end

    columns =
      socket.assigns.shown_fields
      |> Enum.map(&Enum.find(static.fields, fn f -> f.id == &1 end))
      |> Enum.map(& &1.columns)
      |> Enum.concat()
      |> MapSet.new()
      |> MapSet.union(MapSet.new(static.always_columns))
      |> MapSet.union(expanded_columns)

    filters =
      socket.assigns.filters.filters
      |> Enum.map(fn f ->
        %{
          field: String.to_existing_atom(f.field),
          op: String.to_existing_atom(f.op),
          value: f.value
        }
      end)

    %DataTable.Source.Query{
      filters: filters,
      sort: socket.assigns.sort,
      offset: socket.assigns.page * socket.assigns.page_size,
      limit: socket.assigns.page_size,
      fields: columns

      # shown_fields: socket.assigns.shown_fields,
    }
  end

  defp do_query(socket) do
    static = socket.assigns.static
    source = static.source
    query_params = make_query_params(socket)

    %{
      results: results,
      total_results: total_results
    } = DataTable.Source.query(source, query_params)

    # socket =
    #  if socket.assigns.handle_nav do
    #    if nav != socket.assigns.nav do
    #      socket.assigns.handle_nav.(nav)
    #    end
    #    socket
    #  else
    #    assign(socket, :nav, nav)
    #  end

    socket =
      assign(socket, %{
        results: results,
        page_results: Enum.count(results),
        total_results: total_results
      })

    socket
  end

  defp assign_static_data(socket, comp_assigns) do
    source = comp_assigns.source

    filterable_columns = DataTable.Source.filterable_fields(source)
    filter_types = DataTable.Source.filter_types(source)
    id_field = DataTable.Source.key(source)

    fields =
      comp_assigns.col
      |> Enum.map(fn slot = %{__slot__: :col, fields: fields, name: name} ->
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

    static = %{
      source: source,

      # Fields
      fields: fields,
      id_field: id_field,
      default_shown_fields:
        comp_assigns.col
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
        |> Enum.into(%{}),
      always_columns:
        comp_assigns.row_buttons
        |> Enum.map(fn rb -> Map.get(rb, :fields, []) end)
        |> Enum.concat()
        |> Enum.concat(comp_assigns[:always_columns] || [])
        |> Enum.concat([id_field]),
      expanded_fields:
        comp_assigns.row_expanded
        |> Enum.map(fn re -> Map.get(re, :fields, []) end)
        |> Enum.concat(),

      # Sort
      default_sort: nil,

      # Filters
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

    assign(socket, :static, static)
  end

  defp assign_base_render_data(socket) do
    assigns = socket.assigns
    static = assigns.static

    # spec.page_size
    page_size = 20

    assign(socket, %{
      # Selection
      has_selection: assigns.selection != {:include, %{}},
      header_selection:
        case assigns.selection do
          {:include, map} when map_size(map) == 0 -> false
          {:exclude, map} when map_size(map) == 0 -> true
          _ -> :dash
        end,
      selection: assigns.selection,

      # Filters
      # [...]

      # Fields
      header_fields:
        static.fields
        |> Enum.filter(&MapSet.member?(assigns.shown_fields, &1.id))
        |> Enum.map(fn field ->
          filter_field = field.filter_field
          filter_field_op = field.filter_field_op
          sort_field = field.sort_field

          %{
            name: field.name,
            can_sort: sort_field != nil,
            sort:
              case assigns.sort do
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
        Enum.map(static.fields, fn field ->
          {field.name, id_to_string(field.id), MapSet.member?(assigns.shown_fields, field.id)}
        end),

      # Pagination
      page_size: page_size,

      # Slots
      field_slots:
        static.fields
        |> Enum.filter(&MapSet.member?(assigns.shown_fields, &1.id))
        |> Enum.map(& &1.slot),
      target: assigns.myself
    })
  end

  defp assign_query_render_data(socket) do
    assigns = socket.assigns
    static = assigns.static

    page_idx = assigns.page
    page_size = assigns.page_size
    total_results = assigns.total_results
    max_page = div(total_results + (page_size - 1), page_size) - 1

    assign(socket, %{
      # Data
      rows:
        Enum.map(assigns.results, fn row ->
          id = row[static.id_field]

          %{
            id: id,
            data: row,
            expanded: Map.has_key?(assigns.expanded, "#{id}"),
            selected:
              case assigns.selection do
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
    })
  end

  defp field_by_str_id(str_id, socket) do
    id = Map.fetch!(socket.assigns.static.field_id_by_str_id, str_id)
    Map.fetch!(socket.assigns.static.field_by_id, id)
  end

  defp apply_filters_changeset(socket, changeset) do
    static = socket.assigns.static
    changeset = add_filter_defaults(changeset, static)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, data} ->
        socket = assign(socket, :filters, data)

        socket
        |> assign_base_render_data()
        |> do_query()
        |> assign_query_render_data()
        |> assign(%{
          filters_changeset: changeset,
          filters_form: to_form(changeset)
        })

      {:error, changeset} ->
        socket =
          assign(socket, %{
            filters_changeset: changeset,
            filters_form: to_form(changeset)
          })

        assign(socket, :filters_form, to_form(changeset))
    end
  end

  defp nav_from_state(socket) do
    raw_filters = Ecto.Changeset.apply_changes(socket.assigns.filters_changeset)

    %DataTable.NavState{
      filters:
        Enum.map(raw_filters.filters, fn %{field: field, op: op, value: value} ->
          {field, op, value}
        end),
      sort: socket.assigns.sort,
      page: socket.assigns.page + 1
    }
  end

  defp nav_to_state(socket, nav) do
    assigns = socket.assigns

    socket =
      if MapSet.member?(nav.set, :filters) do
        changes = %{
          "filters" =>
            nav.filters
            |> Enum.map(fn {field, op, value} ->
              %{"field" => field, "op" => op, "value" => value}
            end)
        }

        changeset = Filters.changeset(%Filters{}, assigns.static.filter_columns, changes)
        apply_filters_changeset(socket, changeset)
      else
        socket
      end

    socket =
      if MapSet.member?(nav.set, :sort) do
        assign(socket, :sort, nav.sort)
      else
        socket
      end

    socket =
      if MapSet.member?(nav.set, :page) do
        assign(socket, :page, max(nav.page - 1, 0))
      else
        socket
      end

    socket
  end

  defp dispatch_handle_nav(socket) do
    handle_nav = socket.assigns.handle_nav
    new_nav = nav_from_state(socket)

    if handle_nav != nil and new_nav != socket.assigns.dispatched_nav do
      handle_nav.(new_nav)
    end

    assign(socket, :dispatched_nav, new_nav)
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

  defp cycle_sort(sort_state, field) do
    case sort_state do
      {^field, :asc} -> {field, :desc}
      {^field, :desc} -> nil
      _ -> {field, :asc}
    end
  end

  defp put_page(state, page) when is_binary(page) do
    {page, ""} = Integer.parse(page)
    assign(state, :page, page)
  end

  defp put_page(state, page) when is_integer(page) do
    assign(state, :page, page)
  end
end
