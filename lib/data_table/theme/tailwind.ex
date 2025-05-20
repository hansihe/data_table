defmodule DataTable.Theme.Tailwind do
  @doc """
  A modern data table theme implemented using Tailwind.

  Design inspired by https://www.figma.com/community/file/1021406552622495462/data-table-design-components-free-ui-kit
  by HBI Agency and Violetta Nekrasova according to CC BY 4.0.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import DataTable.Theme.Tailwind.Components

  alias DataTable.Theme.Util

  # If using this module as the base for your own theme, you may wish to use the
  # upstream libraries instead of these vendored versions.
  alias DataTable.Theme.Tailwind.Heroicons # From `:heroicons` Heroicons
  alias DataTable.Theme.Tailwind.Dropdown # From `:petal_components` PetalComponents.Dropdown`

  attr :size, :atom, default: :small, values: [:small, :medium, :large]
  slot :icon
  slot :inner_block, required: true
  def btn_basic(assigns) do
    ~H"""
    <% classes = [
      "flex cursor-pointer",
      "rounded-lg hover:bg-indigo-50",
      "text-zinc-800 hover:text-indigo-600",
      (if @size == :small, do: "text-sm px-2 py-1 space-x-1"),
      (if @size == :small and @icon != nil, do: "pl-1.5"),
      (if @size == :medium, do: ""),
      (if @size == :medium and @icon == nil, do: ""),
      (if @size == :large, do: ""),
      (if @size == :large and @icon == nil, do: "")
    ] %>

    <div tabindex="0" class={classes}>
      <%= render_slot(@icon) %>
      <div><%= render_slot(@inner_block) %></div>
    </div>
    """
  end

  slot :inner_block, required: true
  def btn_icon(assigns) do
    ~H"""
    <div tabindex="0" class={[
      "cursor-pointer",
      "flex justify-center",
      "rounded-full w-7 h-7",
      "text-zinc-800",
      "hover:text-indigo-600 hover:bg-indigo-50"
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField
  attr :options, :any
  def select(assigns) do
    ~H"""
    <select
      name={@field.name}
      class={[
        "text-sm pl-2 py-1 pr-10",
        "outline-1 !border-0 !ring-0 rounded-lg",
        "bg-zinc-100 text-zinc-800 shadow-indigo-600 outline-indigo-600",
        "focus:text-indigo-600 focus:shadow-[0_0_2px_0px] focus:outline",
      ]}>
      <%= for {id, name} <- @options do %>
        <option value={id} selected={@field.value == id}><%= name %></option>
      <% end %>
    </select>
    """
  end

  attr :field, Phoenix.HTML.FormField
  def text_input(assigns) do
    ~H"""
    <% has_error = @field.errors != [] %>
    <input
      type="text"
      name={@field.name}
      value={@field.value}
      class={[
        "text-sm pl-2 py-1",
        "focus:outline outline-1 !border-0 !ring-0 rounded-lg",
        "bg-zinc-100 text-zinc-800 shadow-indigo-600 outline-indigo-600",
        "focus:shadow-[0_0_2px_0px]",
        (if has_error, do: "outline outline-red-600 !bg-red-50")
      ]}/>
    """
  end

  def root(assigns) do
    ~H"""
    <div>
      <.filter_header
        filters_form={@filters_form}
        can_select={@can_select}
        has_selection={@has_selection}
        selection_actions={@static.selection_actions}
        target={@target}
        top_right_slot={@top_right}
        filter_column_order={@static.filter_column_order}
        filter_columns={@static.filter_columns}
        filters_fields={@static.filters_fields}/>

      <div class="flex flex-col">
        <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
            <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
              <table class="min-w-full divide-y divide-gray-300 bg-white">
                <.table_header
                  can_select={@can_select}
                  header_selection={@header_selection}
                  target={@target}
                  can_expand={@can_expand}
                  row_expanded_slot={@row_expanded}
                  header_fields={@header_fields}
                  togglable_fields={@togglable_fields}/>

                <.table_body
                  rows={@rows}
                  can_select={@can_select}
                  field_slots={@field_slots}
                  has_row_buttons={@has_row_buttons}
                  row_buttons_slot={@row_buttons_slot}
                  can_expand={@can_expand}
                  row_expanded_slot={@row_expanded}
                  target={@target}/>

                <.table_footer
                  page_start_item={@page_start_item}
                  page_end_item={@page_end_item}
                  total_results={@total_results}
                  page={@page}
                  page_size={@page_size}
                  target={@target}
                  has_prev={@has_prev}
                  has_next={@has_next}/>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def filter_header(assigns) do
    ~H"""
    <div class="sm:flex sm:justify-between">
      <div class="flex items-center">
        <div :if={@can_select and @has_selection}>
          <Dropdown.dropdown label="Selection" placement="right">
            <Dropdown.dropdown_menu_item
              :for={%{label: label, action_idx: idx} <- @selection_actions}
              label={label}
              phx-click="selection-action"
              phx-value-action-idx={idx}
              phx-target={@target}/>
          </Dropdown.dropdown>
        </div>

        <.filters_form
          target={@target}
          filters_form={@filters_form}
          filter_column_order={@filter_column_order}
          filter_columns={@filter_columns}
          filters_fields={@filters_fields}/>
      </div>

      <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
        <%= if assigns[:top_right_slot] do %>
          <%= render_slot(@top_right_slot) %>
        <% end %>
      </div>
    </div>
    """
  end

  def table_header(assigns) do
    ~H"""
    <thead class="bg-gray-50">
      <tr class="divide-x divide-gray-200">
        <th :if={@can_select} scope="col" class="w-10 pl-4 !border-0">
          <.checkbox state={@header_selection} on_toggle="toggle-all" phx-target={@target}/>
        </th>

        <th :if={@can_expand} scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 w-10 sm:pl-6 !border-0"></th>

        <th
            :for={{field, idx} <- Enum.with_index(@header_fields)}
            scope="col"
            class={["py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6", (if idx == 0, do: "!border-0")]}>
          <div class="flex items-center justify-between">
            <a :if={not field.can_sort} class="group inline-flex">
              <%= field.name %>
            </a>

            <a :if={field.can_sort} href="#" class="group inline-flex" phx-click="cycle-sort" phx-target={@target} phx-value-sort-toggle-id={field.sort_toggle_id}>
              <%= field.name %>

              <span :if={field.sort == :asc} class="ml-2 flex-none rounded bg-gray-200 text-gray-900 group-hover:bg-gray-300">
                <Heroicons.chevron_down mini class="h-5 w-5"/>
              </span>

              <span :if={field.sort == :desc} class="ml-2 flex-none rounded bg-gray-200 text-gray-900 group-hover:bg-gray-300">
                <Heroicons.chevron_up mini class="h-5 w-5"/>
              </span>

              <span :if={field.sort == nil} class="invisible ml-2 flex-none rounded text-gray-400 group-hover:visible group-focus:visible">
                <Heroicons.chevron_down mini class="h-5 w-5"/>
              </span>
            </a>

            <!--<a :if={field.can_filter} class="text-gray-400" href="#" phx-click="add-field-filter" phx-target={@target} phx-value-filter-id={field.filter_field_id}>
              <Heroicons.funnel class="h-4 w-4"/>
            </a>-->
          </div>
        </th>

        <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6 w-0 whitespace-nowrap !border-0">
          <span class="sr-only">Buttons</span>
          <div class="flex justify-end content-center">
            <Dropdown.dropdown>
              <:trigger_element>
                <Heroicons.list_bullet mini class="h-4 w-4"/>
              </:trigger_element>

              <div class="p-4 bg-white top-4 right-0 rounded space-y-2">
                <div :for={{name, id, checked} <- @togglable_fields} class="relative flex items-start cursor-pointer" phx-click="toggle-field" phx-target={@target} phx-value-field={id}>
                  <div class="flex h-5 w-5 items-center">
                    <div class="border border-gray-300 rounded relative w-[18px] h-[18px]">
                      <Heroicons.check :if={checked} solid={true} class="w-4 text-gray-800"/>
                    </div>
                  </div>
                  <div class="ml-2 text-sm">
                    <label for="comments" class="font-medium text-gray-700"><%= name %></label>
                  </div>
                </div>
              </div>
            </Dropdown.dropdown>
          </div>
        </th>
      </tr>
    </thead>
    """
  end

  def table_body(assigns) do
    ~H"""
    <tbody class="bg-white">
      <%= for row <- @rows do %>
        <tr class="border-t border-gray-200 hover:bg-gray-50 divide-x divide-gray-200">
          <td :if={@can_select} class="pl-4 !border-0">
            <.checkbox state={row.selected} on_toggle="toggle-row" phx-target={@target} phx-value-id={row.id}/>
          </td>

          <td :if={@can_expand} class="cursor-pointer !border-0" phx-click={JS.push("toggle-expanded", page_loading: true)} phx-target={@target} phx-value-data-id={row.id}>
            <% class = if @can_select, do: "ml-5", else: "ml-3" %>
            <Heroicons.chevron_up :if={row.expanded} mini={true} class={"h-5 w-5 " <> class}/>
            <Heroicons.chevron_down :if={not row.expanded} mini={true} class={"h-5 w-5 " <> class}/>
          </td>

          <td
              :for={{field_slot, idx} <- Enum.with_index(@field_slots)}
              class={["whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-6", (if idx == 0, do: "!border-0")]}>
            <%= render_slot(field_slot, row.data) %>
          </td>

          <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm sm:pr-6 !border-0">
            <%= if @has_row_buttons do %>
              <%= render_slot(@row_buttons_slot, row.data) %>
            <% end %>
          </td>
        </tr>

        <tr :if={row.expanded}>
          <td colspan="50">
            <%= render_slot(@row_expanded_slot, row.data) %>
          </td>
        </tr>
      <% end %>
    </tbody>
    """
  end

  def table_footer(assigns) do
    ~H"""
    <tfoot class="bg-gray-50">
      <tr>
        <td colspan="20" class="py-2 px-4">
          <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
            <div>
              <p class="text-sm text-gray-700">
                Showing
                <span class="font-medium"><%= @page_start_item %></span>
                to
                <span class="font-medium"><%= @page_end_item %></span>
                of
                <span class="font-medium"><%= @total_results %></span>
                results
              </p>
            </div>
            <div>
              <% pages = Util.generate_pages(@page, @page_size, @total_results) %>
              <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
                <a :if={@has_prev} phx-click="change-page" phx-target={@target} phx-value-page={@page - 1} class="relative inline-flex items-center rounded-l-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 hover:cursor-pointer focus:z-20">
                  <span class="sr-only">Previous</span>
                  <Heroicons.chevron_left mini={true} class="h-5 w-5"/>
                </a>
                <a :if={not @has_prev} class="relative inline-flex items-center rounded-l-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500">
                  <span class="sr-only">Previous</span>
                  <Heroicons.chevron_left mini={true} class="h-5 w-5"/>
                </a>

                <a
                  :for={{:page, page_num, current} <- pages}
                  phx-click="change-page"
                  phx-target={@target}
                  phx-value-page={page_num}
                  class={[
                    "relative inline-flex items-center border px-4 py-2 text-sm font-medium hover:cursor-pointer focus:z-20",
                    (
                      if current, do: "z-20 border-indigo-500 bg-indigo-50 text-indigo-600",
                        else: "z-10 border-gray-300 bg-white text-gray-500 hover:bg-gray-50"
                    )
                  ]}>
                  <%= page_num + 1 %>
                </a>

                <a :if={@has_next} phx-click="change-page" phx-target={@target} phx-value-page={@page + 1} class="relative inline-flex items-center rounded-r-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 hover:cursor-pointer focus:z-20">
                  <span class="sr-only">Next</span>
                  <Heroicons.chevron_right mini={true} class="h-5 w-5"/>
                </a>
                <a :if={not @has_next} class="relative inline-flex items-center rounded-r-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500">
                  <span class="sr-only">Next</span>
                  <Heroicons.chevron_right mini={true} class="h-5 w-5"/>
                </a>
              </nav>
            </div>
          </div>
        </td>
      </tr>
    </tfoot>
    """
  end

  #defp op_options_and_default(_spec, nil), do: {[], ""}
  #defp op_options_and_default(spec, field_value) do
  #  atom_field = String.to_existing_atom(field_value)
  #  filter_data = Enum.find(spec.filterable_columns, & &1.col_id == atom_field)

  #  if filter_data == nil do
  #    {[], ""}
  #  else
  #    type_map = spec.filter_types[filter_data[:type]] || %{}
  #    ops = type_map[:ops] || []
  #    kvs = Enum.map(ops, fn {filter_id, filter_name} -> {filter_name, filter_id} end)

  #    default_selected = case ops do
  #      [] -> ""
  #      [{id, _} | _] -> id
  #    end

  #    {kvs, default_selected}
  #  end
  #end


  #attr :form, :any
  #attr :target, :any
  #attr :spec, :any

  #attr :filters_fields, :any
  #attr :filterable_fields, :any

  attr :target, :any
  attr :filters_form, :any
  attr :filter_column_order, :any
  attr :filter_columns, :any
  attr :filters_fields, :any
  attr :update_filters, :any
  def filters_form(assigns) do
    ~H"""
    <.form for={@filters_form} phx-target={@target} phx-change="filters-change" phx-submit="filters-change" class="py-3 sm:flex items-start">
      <h3 class="text-sm font-medium text-zinc-800">
        <!-- Filters -->
        <Heroicons.funnel class="w-4 h-8"/>
      </h3>

      <!-- <div aria-hidden="true" class="hidden h-5 w-px bg-gray-300 sm:ml-4 sm:block"></div> -->

      <div class="ml-4 min-h-[32px] flex items-center">
        <div class="-m-1 flex flex-col space-y-2">
          <.inputs_for :let={filter} field={@filters_form[:filters]}>
            <div class="flex flex-row space-x-2">
              <input
                type="hidden"
                name="filters[filters_sort][]"
                value={filter.index}
              />

              <.select
                field={filter[:field]}
                options={Enum.map(@filter_column_order, fn id -> {id, @filter_columns[id].name} end)}/>

              <% field_config = @filter_columns[filter[:field].value] %>
              <.select
                :if={field_config == nil}
                field={filter[:op]}
                options={[]}/>
              <.select
                :if={field_config != nil}
                field={filter[:op]}
                options={Enum.map(field_config.ops_order, fn op_id ->
                  {op_id, field_config.ops[op_id].name}
                end)}/>

              <.text_input field={filter[:value]}/>
              <label>
                <input type="checkbox" name="filters[filters_drop][]" value={filter.index} class="hidden"/>
                <.btn_icon>
                  <Heroicons.trash class="w-4"/>
                </.btn_icon>
              </label>
            </div>
          </.inputs_for>

          <div class="flex flex-row h-8 mx-2">
            <label>
              <input type="checkbox" name="filters[filters_sort][]" class="hidden"/>
              <.btn_basic>
                <:icon>
                  <Heroicons.plus class="w-4"/>
                </:icon>
                Filter
              </.btn_basic>
            </label>
          </div>
        </div>
      </div>
    </.form>
    """
  end

end
