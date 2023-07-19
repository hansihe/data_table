defmodule DataTable do
  use Phoenix.LiveComponent

  alias Phoenix.LiveView.JS

  alias DataTable.Spec
  alias DataTable.NavState

  import DataTable.Components

  def id_to_string(id) when is_binary(id), do: id

  attr :id, :any,
    required: true,
    doc: """
    `live_data_table` is a stateful component, and requires an `id`.
    See `LiveView.LiveComponent` for more information.
    """

  attr :source, :any,
    required: true,
    doc: """
    """

  attr :nav, :any,
    doc: """
    Override the navigation state of the table.
    Most likely only present when `handle_nav` is also present.

    `nil` will be counted as no change.
    """

  attr :handle_nav, :any,
    doc: """
    Called when the navigation state of the table has changed.
    If present, the navigation data should be passed back into the `nav` parameter.
    """

  attr :always_columns, :list,
    doc: """
    A list of column ids that will always be loaded.
    """

  slot :col, doc: "One `:col` should be sepecified for each potential column in the table" do
    attr :name, :string,
      required: true,
      doc: "Name in column header. Must be unique"

    # default: true
    attr :visible, :boolean,
      doc: "Default visibility of the column"

    # default: []
    attr :fields, :list,
      doc: "List of `field`s that will be queried when this field is visible"

    attr :filter_field, :atom,
      doc: """
      If present, cells will have a filter shortcut. The filter shortcut
      will apply a filter for the specified field. Defaults to the first
      field in `fields`.
      """
    # default: :eq
    attr :filter_field_op, :atom,
      doc: "The filter op type which will be used for the cell filter shortcut"

    attr :sort_field, :atom,
      doc: """
      If present, columns will be sortable. The sort will occur on
      the specified field. Defaults to the first field in `fields`.
      """
  end

  slot :row_expanded, doc: "Markup which will be rendered when a row is expanded" do
    # default: []
    attr :fields, :list,
      doc: "List of `field`s that will be queried when a row is expanded"
  end

  slot :top_right, doc: "Markup in the top right corner of the table"

  slot :row_buttons, doc: "Markup in the rightmost side of each row in the table" do
    attr :fields, :list,
      doc: "List of `field`s that will be queried when this field is visible"
  end

  slot :selection_action do
    attr :label, :string,
      required: true
    attr :handle_action, :any,
      required: true
  end

  @spec live_data_table(assigns :: Socket.assigns()) :: Phoenix.LiveView.Rendered.t()
  def live_data_table(assigns) do
    ~H"""
    <.live_component module={DataTable} {assigns} />
    """
  end

  def render(assigns) do
    DataTable.TailwindTheme.top(assigns)
  end

  def do_query(socket) do
    spec = socket.assigns.spec
    nav = socket.assigns.nav
    source = spec.source

    expanded_columns =
      if map_size(socket.assigns.expanded) > 0 do
        MapSet.new(socket.assigns.spec.expanded_fields)
      else
        MapSet.new()
      end

    columns =
      socket.assigns.shown_fields
      |> Enum.map(&Enum.find(socket.assigns.spec.fields, fn f -> f.id == &1 end))
      |> Enum.map(& &1.columns)
      |> Enum.concat()
      |> MapSet.new()
      |> MapSet.union(MapSet.new(socket.assigns.spec.always_columns))
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

    params = %{
      shown_fields: socket.assigns.shown_fields,
      shown_columns: columns,
      sort: nav.sort,
      page: nav.page,
      page_size: spec.page_size,
      filters: filters
    }

    %{
      results: results,
      total_results: total_results
    } = DataTable.Source.query(source, params)

    socket =
      if socket.assigns.handle_nav do
        encoded_nav = NavState.encode(nav, spec)
        socket.assigns.handle_nav.(encoded_nav)
        socket
      else
        assign(socket, :nav, nav)
      end

    socket = assign(socket, %{
      results: results,
      page_results: Enum.count(results),
      total_results: total_results
    })

    socket
  end

  def assign_render_data(socket) do
    assigns = socket.assigns
    nav = assigns.nav
    spec = assigns.spec

    page_idx = nav.page
    page_size = spec.page_size
    total_results = assigns.total_results
    max_page = div(total_results + (page_size - 1), page_size) - 1

    data = %{
      # Selection
      can_select: spec.selection_actions != nil and
        spec.selection_actions != [],
      has_selection: assigns.selection != {:include, %{}},
      header_selection: case assigns.selection do
        {:include, map} when map_size(map) == 0 -> false
        {:exclude, map} when map_size(map) == 0 -> true
        _ -> :dash
      end,
      selection: assigns.selection,
      selection_actions: Enum.map(spec.selection_actions, fn {{name, _action_fn}, idx} ->
        %{
          label: name,
          action_idx: idx
        }
      end),

      filters_form: assigns.filters_form,
      filters_default_field: Atom.to_string(List.first(spec.filterable_columns)[:col_id]),
      filters_fields:
        spec.filterable_columns
        |> Enum.map(fn col ->
          %{
            name: Atom.to_string(col.col_id),
            id_str: Atom.to_string(col.col_id),
          }
        end),

      header_fields:
        spec.fields
        |> Enum.filter(&MapSet.member?(assigns.shown_fields, &1.id))
        |> Enum.map(fn field ->
          sort_field = field.sort_field
          %{
            name: field.name,
            can_sort: sort_field != nil,
            sort: case nav.sort do
              {^sort_field, :asc} -> :asc
              {^sort_field, :desc} -> :desc
              _ -> nil
            end,
            sort_toggle_id: Atom.to_string(field.sort_field),
          }
        end),

      togglable_fields: Enum.map(spec.fields, fn field ->
        {field.name, id_to_string(field.id), MapSet.member?(assigns.shown_fields, field.id)}
      end),

      rows: Enum.map(assigns.results, fn row ->
        id = row[spec.id_field]
        %{
          id: id,
          data: row,
          expanded: Map.has_key?(assigns.expanded, "#{id}"),
          selected: case assigns.selection do
            {:include, %{^id => _}} -> true
            {:include, %{}} -> false
            {:exclude, %{^id => _}} -> false
            {:exclude, %{}} -> true
          end
        }
      end),

      # Pagination
      page_idx: page_idx,
      page_start_item: min(page_size * page_idx, total_results),
      page_end_item: min(page_size * page_idx + page_size, total_results),
      page_size: page_size,
      total_results: total_results,
      page_max: max_page,
      has_prev: page_idx > 0,
      has_next: page_idx < max_page,

      # Slots
      top_right_slot: assigns.top_right,
      can_expand: assigns.row_expanded != nil
        and assigns.row_expanded != [],
      row_expanded_slot: assigns.row_expanded,
      has_row_buttons: assigns.row_buttons != nil
        and assigns.row_buttons != [],
      row_buttons_slot: assigns.row_buttons,
      field_slots:
        spec.fields
        |> Enum.filter(&MapSet.member?(assigns.shown_fields, &1.id))
        |> Enum.map(& &1.slot),

      target: assigns.myself,
      # TODO remove
      spec: assigns.spec
    }

    assign(socket, data)
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = if socket.assigns[:first] != false do
      spec = assigns_to_spec(assigns)

      #nav = if assigns[:query] do
      #  params = URI.decode_query(assigns.query)
      #  NavState.decode(nav, params, spec)
      #else
      #  nav
      #end

      filters = %DataTable.Filters{}
      filters_changeset = DataTable.Filters.changeset(filters, spec, %{})
      filters_form = Phoenix.Component.to_form(filters_changeset)

      socket
      |> assign(%{
        id: assigns.id,
        nav: NavState.default(spec),
        handle_nav: assigns[:handle_nav],
        expanded: %{},
        shown_fields: MapSet.new(spec.default_shown_fields),
        spec: spec,
        selection: {:include, %{}},
        filters: filters,
        filters_form: filters_form,
        first: false
      })
      |> do_query()
    else
      socket
    end

    copy_assigns = Map.take(assigns, [:row_buttons, :row_expanded, :top_right])
    socket = assign(socket, copy_assigns)

    # Update nav state if present
    nav = assigns[:nav]
    socket = if nav != nil do
      if nav != socket.assigns.nav do
        socket.assigns.handle_nav.(nav)
      end

      socket
      |> assign(:nav, nav)
      |> do_query()
    else
      socket
    end

    socket = assign_render_data(socket)

    {:ok, socket}
  end

  def assigns_to_spec(assigns) do
    source = assigns.source
    id_column = DataTable.Source.key(source)

    fields =
      assigns.col
      |> Enum.map(fn slot = %{__slot__: :col, fields: fields, name: name} ->
        %{
          id: name,
          name: name,
          columns: fields,
          slot: slot,
          sort_field: Map.get(slot, :sort_field),
          filter_type: nil
        }
      end)

    default_shown_fields =
      assigns.col
      |> Enum.map(fn
        %{visible: false} -> []
        %{name: name} -> [name]
      end)
      |> Enum.concat()

    always_columns =
      assigns.row_buttons
      |> Enum.map(fn rb -> Map.get(rb, :fields, []) end)
      |> Enum.concat()
      |> Enum.concat(assigns[:always_columns] || [])
      |> Enum.concat([id_column])

    expanded_fields =
        assigns.row_expanded
        |> Enum.map(fn re -> Map.get(re, :fields, []) end)
        |> Enum.concat()

    field_by_id =
      fields
      |> Enum.map(&{&1.id, &1})
      |> Enum.into(%{})

    field_id_by_str_id =
      fields
      |> Enum.map(fn
        %{id: id} when is_atom(id) -> {Atom.to_string(id), id}
        %{id: id} when is_binary(id) -> {id, id}
      end)
      |> Enum.into(%{})

    filterable_columns = DataTable.Source.filterable_columns(source)
    filter_types = DataTable.Source.filter_types(source)

    #filterable_fields =
    #  fields
    #  |> Enum.filter(&(&1.filter_type != nil))
    #  |> Enum.map(&(&1.id))

    %{
      id_field: DataTable.Source.key(source),
      fields: fields,
      default_shown_fields: default_shown_fields,
      always_columns: always_columns,
      #filterable_fields: filterable_fields,
      filterable_columns: filterable_columns,
      filter_types: filter_types,
      expanded_fields: expanded_fields,
      source: source,

      field_by_id: field_by_id,
      field_id_by_str_id: field_id_by_str_id,

      selection_actions: [],
      page_size: 20,
      default_sort: nil,
    }
  end

  def field_by_str_id(str_id, spec) do
    id = Map.fetch!(spec.field_id_by_str_id, str_id)
    Map.fetch!(spec.field_by_id, id)
  end

  def handle_event("toggle-field", %{"field" => field}, socket) do
    field_data = field_by_str_id(field, socket.assigns.spec)

    shown_fields = if MapSet.member?(socket.assigns.shown_fields, field_data.id) do
      MapSet.delete(socket.assigns.shown_fields, field_data.id)
    else
      MapSet.put(socket.assigns.shown_fields, field_data.id)
    end

    socket =
      socket
      |> assign(:shown_fields, shown_fields)
      |> do_query()
      |> assign_render_data()

    {:noreply, socket}
  end

  def handle_event("cycle-sort", %{"sort-toggle-id" => field_str}, socket) do
    spec = socket.assigns.spec

    # TODO validate further. Not a security issue, but nice to have.
    field = String.to_existing_atom(field_str)

    socket =
      socket
      |> update(:nav, &NavState.cycle_sort(&1, field, spec))
      |> do_query()
      |> assign_render_data()

    {:noreply, socket}
  end

  def handle_event("toggle-expanded", %{"data-id" => data_id}, socket) do
    spec = socket.assigns.spec

    expanded = if Map.has_key?(socket.assigns.expanded, data_id) do
      Map.delete(socket.assigns.expanded, data_id)
    else
      Map.put(socket.assigns.expanded, data_id, true)
    end

    socket =
      socket
      |> assign(:expanded, expanded)
      |> do_query()
      |> assign_render_data()

    {:noreply, socket}
  end

  def handle_event("change-page", %{"page" => page}, socket) do
    socket =
      socket
      |> update(:nav, &NavState.put_page(&1, page))
      |> do_query()
      |> assign_render_data()

    {:noreply, socket}
  end

  def handle_event("add-filter", _params, socket) do
    spec = socket.assigns.spec
    nav = socket.assigns.nav

    {_filter_id, nav} = NavState.add_filter(nav, spec)

    socket =
      socket
      |> assign(:nav, nav)
      |> assign_render_data()

    {:noreply, socket}
  end

  def handle_event("toggle-all", _params, socket) do
    selection = case socket.assigns.selection do
      {:include, map} when map_size(map) == 0 -> {:exclude, %{}}
      {:exclude, map} when map_size(map) == 0 -> {:include, %{}}
      _ -> {:exclude, %{}}
    end

    socket =
      socket
      |> assign(:selection, selection)
      |> assign_render_data()

    {:noreply, socket}
  end

  def handle_event("toggle-row", %{"id" => row_id}, socket) do
    {row_id, ""} = Integer.parse(row_id)

    selection = case socket.assigns.selection do
      {:include, map = %{^row_id => _}} -> {:include, Map.delete(map, row_id)}
      {:include, map} -> {:include, Map.put(map, row_id, nil)}
      {:exclude, map = %{^row_id => _}} -> {:exclude, Map.delete(map, row_id)}
      {:exclude, map} -> {:exclude, Map.put(map, row_id, nil)}
    end

    socket =
      socket
      |> assign(:selection, selection)
      |> assign_render_data()

    {:noreply, socket}
  end

  def handle_event("selection-action", %{"action-idx" => action_idx}, socket) do
    {action_idx, ""} = Integer.parse(action_idx)
    {_name, action_fn} = Enum.fetch!(socket.assigns.spec.selection_actions, action_idx)

    selection = socket.assigns.selection
    action_fn.(selection)

    socket = assign_render_data(socket)
    {:noreply, socket}
  end

  def handle_event("filters-change", params, socket) do
    filters_changes = params["filters"] || %{}

    filters_changeset =
      %DataTable.Filters{}
      |> DataTable.Filters.changeset(socket.assigns.spec, filters_changes)
      |> Map.put(:action, :validate)

    {socket, changeset} =
      case Ecto.Changeset.apply_action(filters_changeset, :validate) do
        {:ok, filters} ->
          IO.inspect(filters)
          {assign(socket, :filters, filters), filters_changeset}
        {:error, changeset} -> {socket, changeset}
      end

    socket =
      socket
      |> assign(:filters_form, Phoenix.Component.to_form(changeset))

    socket =
      if changeset.valid? do
        do_query(socket)
      else
        socket
      end

    socket = assign_render_data(socket)

    {:noreply, socket}
  end

end
