defmodule DataTable do
  use Phoenix.LiveComponent

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
    ~H"""
    <div>

      <!-- Filter Header -->

      <div class="sm:flex sm:justify-between">
        <div class="flex items-center">
          <%= if @spec.selection_actions != nil and @selection != {:include, %{}} do %>
            <div>
              <PetalComponents.Dropdown.dropdown label="Selection" js_lib="live_view_js" placement="right">
                <%= for {{name, _action_fn}, idx} <- Enum.with_index(@spec.selection_actions) do %>
                  <PetalComponents.Dropdown.dropdown_menu_item label={name} phx-click="selection-action" phx-value-action-idx={idx} phx-target={@myself}/>
                <% end %>
              </PetalComponents.Dropdown.dropdown>
            </div>
          <% end %>

          <div class="px-4 py-3 sm:flex sm:items-center">
            <h3 class="text-sm font-medium text-gray-500">
              Filters
            </h3>

            <div aria-hidden="true" class="hidden h-5 w-px bg-gray-300 sm:ml-4 sm:block"></div>

            <div class="mt-2 sm:mt-0 sm:ml-4">
              <div class="-m-1 flex flex-wrap items-center">

                <!--
                <%= for filter_id <- @nav.filter_order do %>
                  <% cancel_filter = fn -> send_update(__MODULE__, id: @id, action: :cancel_filter, filter_id: filter_id) end %>
                  <% change_filter = fn filter, valid -> send_update(__MODULE__, id: @id, action: :change_filter, filter_id: filter_id, filter: filter, valid: valid) end %>
                  <.live_component
                      id={"filter-#{filter_id}"}
                      module={DataTable.FilterPill}
                      spec={@spec}
                      state={@nav.filter_state[filter_id]}
                      cancel_filter={cancel_filter}
                      change_filter={change_filter}/>
                <% end %>

                <span phx-click="add-filter" phx-target={@myself} class="m-1 inline-flex items-center rounded-full border border-gray-200 bg-white p-2 text-gray-400 cursor-pointer hover:bg-gray-200 hover:text-gray-500">
                  <Heroicons.plus class="w-4 h-4"/>
                </span>
                -->

                <!--

                <.form for={@filters} phx-target={@myself} phx-change="filters-change">

                  <.inputs_for :let={filter} field={@form[:filters]}>
                    <input type="hidden" name="filters[filters_order][]" value={filter.index}/>
                    <.input type="text" field={filter[:field]}/>
                    <label>
                      <input type="checkbox" name="filters[filters_order][]" value={filter.index} class="hidden" />
                      drop
                    </label>
                  </.inputs_for>

                  <label class="m-1 inline-flex items-center rounded-full border border-gray-200 bg-white p-2 text-gray-400 cursor-pointer hover:bg-gray-200 hover:text-gray-500">
                    <input type="checkbox" name="filters[filters_order][]" class="hidden"/>
                    <Heroicons.plus class="w-4 h-4"/>
                  </label>

                </.form>

                -->

              </div>
            </div>
          </div>
        </div>

        <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
          <%= if assigns[:top_right] do %>
            <%= render_slot(@top_right) %>
          <% end %>
        </div>
      </div>

      <!-- End Filter Header -->

      <!-- Table Container -->

      <.table_container>
        <table class="min-w-full divide-y divide-gray-300 bg-white">

          <!-- Table Header -->

          <thead class="bg-gray-50">
            <tr>
              <%= if @spec.selection_actions != nil do %>
                <th scope="col" class="w-10 pl-4">
                  <% toggle_state = case @selection do
                    {:include, map} when map_size(map) == 0 -> false
                    {:exclude, map} when map_size(map) == 0 -> true
                    _ -> :dash
                  end %>

                  <.checkbox state={toggle_state} on_toggle="toggle-all" phx-target={@myself}/>
                </th>
              <% end %>

              <%= if @row_expanded do %>
                <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 w-10 sm:pl-6"></th>
              <% end %>

              <%= for field <- @spec.fields, MapSet.member?(@shown_fields, field.id) do %>
                <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">
                  <a href="#" class="group inline-flex" phx-click="cycle-sort" phx-target={@myself} phx-value-field={id_to_string(field.id)}>
                    <%= field.name %>

                    <%= if Map.get(field, :sortable, true) do %>
                      <% field_id = field.id %>
                      <%= case @nav.sort do %>
                        <% {^field_id, :asc} -> %>
                          <span class="ml-2 flex-none rounded bg-gray-200 text-gray-900 group-hover:bg-gray-300">
                            <Heroicons.chevron_down mini={true} class="h-5 w-5"/>
                          </span>

                        <% {^field_id, :desc} -> %>
                          <span class="ml-2 flex-none rounded bg-gray-200 text-gray-900 group-hover:bg-gray-300">
                            <Heroicons.chevron_up mini={true} class="h-5 w-5"/>
                          </span>

                        <% _ -> %>
                          <span class="invisible ml-2 flex-none rounded text-gray-400 group-hover:visible group-focus:visible">
                            <Heroicons.chevron_down mini={true} class="h-5 w-5"/>
                          </span>
                      <% end %>
                    <% end %>
                  </a>
                </th>
              <% end %>

              <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6">
                <span class="sr-only">Buttons</span>
                <div class="flex justify-end content-center">
                  <PetalComponents.Dropdown.dropdown js_lib="live_view_js">
                    <:trigger_element>
                      <Heroicons.list_bullet mini class="h-4 w-4"/>
                    </:trigger_element>

                    <div class="p-4 bg-white top-4 right-0 rounded space-y-2">
                      <%= for field <- @spec.fields do %>
                        <div class="relative flex items-start cursor-pointer" phx-click="toggle-field" phx-target={@myself} phx-value-field={id_to_string(field.id)}>
                          <div class="flex h-5 w-5 items-center">
                            <!--<input id="comments" aria-describedby="comments-description" name="comments" type="checkbox" class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"> -->
                            <div class="border border-gray-300 rounded relative w-[18px] h-[18px]">
                              <%= if MapSet.member?(@shown_fields, field.id) do %>
                                <Heroicons.check solid={true} class="w-4 text-gray-800"/>
                              <% end %>
                            </div>
                          </div>
                          <div class="ml-2 text-sm">
                            <label for="comments" class="font-medium text-gray-700"><%= field.name %></label>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </PetalComponents.Dropdown.dropdown>
                </div>
              </th>
            </tr>
          </thead>

          <!-- End Table Head -->

          <!-- Table Body -->

          <tbody class="bg-white">

            <%= for result <- @results do %>
              <% id = result[@spec.id_field] %>
              <% expanded = Map.has_key?(@expanded, "#{id}") %>
              <tr class="border-t border-gray-200 hover:bg-gray-50">

                <%= if @spec.selection_actions != nil do %>
                  <td class="pl-4">
                    <% toggle_state = case @selection do
                      {:include, %{ ^id => _ }} -> true
                      {:include, %{}} -> false
                      {:exclude, %{ ^id => _ }} -> false
                      {:exclude, %{}} -> true
                    end %>

                    <.checkbox state={toggle_state} on_toggle="toggle-row" phx-target={@myself} phx-value-id={result[@spec.id_field]}/>
                  </td>
                <% end %>

                <%= if @row_expanded do %>
                  <td class="cursor-pointer" phx-click="toggle-expanded" phx-target={@myself} phx-value-data-id={result[@spec.id_field]}>
                    <% class = if @spec.selection_actions == nil, do: "ml-5", else: "ml-3" %>

                    <%= if expanded do %>
                      <Heroicons.chevron_up mini={true} class={"h-5 w-5 " <> class}/>
                    <% else %>
                      <Heroicons.chevron_down mini={true} class={"h-5 w-5 " <> class}/>
                    <% end %>
                  </td>
                <% end %>

                <%= for field <- @spec.fields, MapSet.member?(@shown_fields, field.id) do %>
                  <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-6">
                    <%= render_slot(field.slot, result) %>
                  </td>
                <% end %>

                <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm sm:pr-6">
                  <%= if assigns[:row_buttons] do %>
                    <%= render_slot(@row_buttons, result) %>
                  <% end %>
                </td>
              </tr>
              <%= if expanded do %>
                <tr>
                  <td colspan="20">
                    <%= render_slot(@row_expanded, result) %>
                  </td>
                </tr>
              <% end %>
            <% end %>
          </tbody>

          <!-- End Table Body -->

          <!-- Table Footer -->

          <tfoot class="bg-gray-50">
            <tr>
              <td colspan="20" class="py-2 px-4">
                <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
                  <div>
                    <p class="text-sm text-gray-700">
                      Showing
                      <span class="font-medium"><%= min(@spec.page_size * @nav.page, @total_results) %></span>
                      to
                      <span class="font-medium"><%= min((@spec.page_size * @nav.page + @spec.page_size), @total_results) %></span>
                      of
                      <span class="font-medium"><%= @total_results %></span>
                      results
                    </p>
                  </div>
                  <div>
                    <% {has_prev, has_next, pages} = generate_pages(@nav.page, @spec.page_size, @total_results) %>
                    <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
                      <%= if has_prev do %>
                        <a phx-click="change-page" phx-target={@myself} phx-value-page={@nav.page - 1} class="relative inline-flex items-center rounded-l-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 hover:cursor-pointer focus:z-20">
                          <span class="sr-only">Previous</span>
                          <Heroicons.chevron_left mini={true} class="h-5 w-5"/>
                        </a>
                      <% else %>
                        <a class="relative inline-flex items-center rounded-l-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500">
                          <span class="sr-only">Previous</span>
                          <Heroicons.chevron_left mini={true} class="h-5 w-5"/>
                        </a>
                      <% end %>

                      <%= for page <- pages do %>
                        <%= case page do %>
                          <% {:page, page_num, true} -> %>
                            <a phx-click="change-page" phx-target={@myself} phx-value-page={page_num} aria-current="page" class="relative z-10 inline-flex items-center border border-indigo-500 bg-indigo-50 px-4 py-2 text-sm font-medium text-indigo-600 hover:cursor-pointer focus:z-20"><%= page_num + 1 %></a>
                          <% {:page, page_num, false} -> %>
                            <a phx-click="change-page" phx-target={@myself} phx-value-page={page_num} class="relative inline-flex items-center border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 hover:cursor-pointer focus:z-20"><%= page_num + 1 %></a>
                        <% end %>
                      <% end %>

                      <%= if has_next do %>
                        <a phx-click="change-page" phx-target={@myself} phx-value-page={@nav.page + 1} class="relative inline-flex items-center rounded-r-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 hover:cursor-pointer focus:z-20">
                          <span class="sr-only">Next</span>
                          <Heroicons.chevron_right mini={true} class="h-5 w-5"/>
                        </a>
                      <% else %>
                        <a class="relative inline-flex items-center rounded-r-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500">
                          <span class="sr-only">Next</span>
                          <Heroicons.chevron_right mini={true} class="h-5 w-5"/>
                        </a>
                      <% end %>
                    </nav>
                  </div>
                </div>
              </td>
            </tr>
          </tfoot>

          <!-- End Table Footer -->

        </table>
      </.table_container>

    </div>
    """
  end

  def generate_pages(page, page_size, total_results) do
    max_page = div(total_results + (page_size - 1), page_size) - 1

    middle_pages =
      (page - 3)..(page + 3)
      |> Enum.filter(&(&1 >= 0))
      |> Enum.filter(&(&1 <= max_page))

    pages = Enum.map(middle_pages, fn i ->
      {:page, i, i == page}
    end)

    {
      page > 0,
      page < max_page,
      pages,
    }
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
      nav.filter_order
      |> Enum.map(&(Map.fetch!(nav.filter_state, &1)))
      |> Enum.map(fn
        %{field: field} when is_binary(field) ->
          Map.fetch!(spec.field_id_by_str_id, field)

        %{field: field} when is_atom(field) ->
          true = Map.has_key?(spec.field_by_id, field)
          field
      end)
      |> Enum.map(&(%{&1 | field: Spec.Table.resolve_id(&1.field, spec)}))

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

    #nav = NavState.encode(nav, spec)
    #socket =
    #  if socket.assigns.handle_nav do
    #    socket.assigns.handle_nav.(nav)
    #    socket
    #  else
    #    assign(socket, :nav, nav)
    #  end

    socket = assign(socket, %{
      results: results,
      page_results: Enum.count(results),
      total_results: total_results
    })

    socket
  end

  def mount(socket) do
    socket = assign(socket, :filters, filters_changeset(%DataTable.Filters{}, %{}))
    {:ok, socket}
  end

  def update(%{action: :cancel_filter, filter_id: filter_id}, socket) do
    socket =
      socket
      |> update(:nav, &NavState.remove_filter(&1, filter_id))
      |> do_query()
    {:ok, socket}
  end

  def update(%{action: :change_filter, filter_id: filter_id, filter: filter, valid: valid}, socket) do
    spec = socket.assigns.spec

    if valid do
      socket =
        socket
        |> update(:nav, &NavState.set_filter(&1, filter_id, filter, spec))
        |> do_query()

      {:ok, socket}
    else
      {:ok, socket}
    end
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

      socket
      |> assign(%{
        id: assigns.id,
        nav: NavState.default(spec),
        handle_nav: assigns[:handle_nav],
        expanded: %{},
        shown_fields: MapSet.new(spec.default_shown_fields),
        spec: spec,
        selection: {:include, %{}},
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

    {:ok, socket}
  end

  def assigns_to_spec(assigns) do
    source = assigns.source

    fields =
      assigns.col
      |> Enum.map(fn slot = %{__slot__: :col, fields: fields, name: name} ->
        %{
          id: name,
          name: name,
          columns: fields,
          slot: slot,
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

    socket = assign(socket, :shown_fields, shown_fields)
    {:noreply, socket}
  end

  def handle_event("cycle-sort", %{"field" => field}, socket) do
    spec = socket.assigns.spec

    socket =
      socket
      |> update(:nav, &NavState.cycle_sort(&1, field, spec))
      |> do_query()

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

    {:noreply, socket}
  end

  def handle_event("change-page", %{"page" => page}, socket) do
    socket =
      socket
      |> update(:nav, &NavState.put_page(&1, page))
      |> do_query()
    {:noreply, socket}
  end

  def handle_event("add-filter", _params, socket) do
    spec = socket.assigns.spec
    nav = socket.assigns.nav

    {_filter_id, nav} = NavState.add_filter(nav, spec)

    socket = assign(socket, :nav, nav)
    {:noreply, socket}
  end

  def handle_event("toggle-all", _params, socket) do
    selection = case socket.assigns.selection do
      {:include, map} when map_size(map) == 0 -> {:exclude, %{}}
      {:exclude, map} when map_size(map) == 0 -> {:include, %{}}
      _ -> {:exclude, %{}}
    end

    socket = assign(socket, :selection, selection)

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

    socket = assign(socket, :selection, selection)

    {:noreply, socket}
  end

  def handle_event("selection-action", %{"action-idx" => action_idx}, socket) do
    {action_idx, ""} = Integer.parse(action_idx)
    {_name, action_fn} = Enum.fetch!(socket.assigns.spec.selection_actions, action_idx)

    selection = socket.assigns.selection
    action_fn.(selection)

    {:noreply, socket}
  end




  def handle_event("filters-change", params, socket) do
    filters_changes = params["filters"] || %{}

    filters_changeset =
      socket.assigns.filters
      |> filters_changeset(filters_changes)

    IO.inspect(filters_changeset)

    socket = assign(socket, :filters, filters_changeset)

    {:noreply, socket}
  end

  def filters_changeset(data, attrs) do
    import Ecto.Changeset

    cast(data, attrs, [])
    |> cast_embed(:filters,
      with: &filter_changeset/2,
      sort_param: :filters_order,
      drop_param: :filters_delete
    )
  end

  def filter_changeset(data, attrs) do
    import Ecto.Changeset

    cast(data, attrs, [:field, :op, :value])
  end

end
