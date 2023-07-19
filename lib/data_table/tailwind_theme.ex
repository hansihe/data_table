defmodule DataTable.TailwindTheme do
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  import DataTable.Components

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

  def top(assigns) do
    ~H"""
    <div>
      <.filter_header
        can_select={@can_select}
        has_selection={@has_selection}
        selection_actions={@selection_actions}
        filters_form={@filters_form}
        target={@target}
        top_right_slot={@top_right_slot}
        spec={@spec}
        filters_fields={@filters_fields}
        filters_default_field={@filters_default_field}/>

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
                  row_expanded_slot={@row_expanded_slot}
                  header_fields={@header_fields}
                  togglable_fields={@togglable_fields}/>

                <.table_body
                  rows={@rows}
                  can_select={@can_select}
                  field_slots={@field_slots}
                  has_row_buttons={@has_row_buttons}
                  row_buttons_slot={@row_buttons_slot}
                  can_expand={@can_expand}
                  row_expanded_slot={@row_expanded_slot}
                  target={@target}/>

                <.table_footer
                  page_start_item={@page_start_item}
                  page_end_item={@page_end_item}
                  total_results={@total_results}
                  page_idx={@page_idx}
                  page_size={@page_size}
                  total_results={@total_results}
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
          <PetalComponents.Dropdown.dropdown label="Selection" js_lib="live_view_js" placement="right">
            <PetalComponents.Dropdown.dropdown_menu_item
              :for={%{label: label, action_idx: idx} <- @selection_actions}
              label={label}
              phx-click="selection-action"
              phx-value-action-idx={idx}
              phx-target={@target}/>
          </PetalComponents.Dropdown.dropdown>
        </div>

        <div class="px-4 py-3 sm:flex sm:items-center">
          <h3 class="text-sm font-medium text-gray-500">
            Filters
          </h3>

          <div aria-hidden="true" class="hidden h-5 w-px bg-gray-300 sm:ml-4 sm:block"></div>

          <div class="mt-2 sm:mt-0 sm:ml-4">
            <div class="-m-1 flex flex-wrap items-center">
              <.filters_form
                form={@filters_form}
                target={@target}
                spec={@spec}
                filters_fields={@filters_fields}
                filters_default_field={@filters_default_field}/>
            </div>
          </div>
        </div>
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
        <th :if={@can_select} scope="col" class="w-10 pl-4">
          <.checkbox state={@header_selection} on_toggle="toggle-all" phx-target={@target}/>
        </th>

        <th :if={@can_expand} scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 w-10 sm:pl-6"></th>

        <th :for={field <- @header_fields} scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">
          <a :if={not field.can_sort} class="group inline-flex">
            <%= field.name %>
          </a>

          <a :if={field.can_sort} href="#" class="group inline-flex" phx-click="cycle-sort" phx-target={@target} phx-value-sort-toggle-id={field.sort_toggle_id}>
            <%= field.name %>

            <span :if={field.sort == :asc} class="ml-2 flex-none rounded bg-gray-200 text-gray-900 group-hover:bg-gray-300">
              <Heroicons.chevron_down mini={true} class="h-5 w-5"/>
            </span>

            <span :if={field.sort == :desc} class="ml-2 flex-none rounded bg-gray-200 text-gray-900 group-hover:bg-gray-300">
              <Heroicons.chevron_up mini={true} class="h-5 w-5"/>
            </span>

            <span :if={field.sort == nil} class="invisible ml-2 flex-none rounded text-gray-400 group-hover:visible group-focus:visible">
              <Heroicons.chevron_down mini={true} class="h-5 w-5"/>
            </span>
          </a>
        </th>

        <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6 w-0 whitespace-nowrap !border-0">
          <span class="sr-only">Buttons</span>
          <div class="flex justify-end content-center">
            <PetalComponents.Dropdown.dropdown js_lib="live_view_js">
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
            </PetalComponents.Dropdown.dropdown>
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
          <td :if={@can_select} class="pl-4">
            <.checkbox state={@selected} on_toggle="toggle-row" phx-target={@target} phx-value-id={row.id}/>
          </td>

          <td :if={@can_expand} class="cursor-pointer" phx-click={JS.push("toggle-expanded", page_loading: true)} phx-target={@target} phx-value-data-id={row.id}>
            <% class = if @can_select, do: "ml-5", else: "ml-3" %>
            <Heroicons.chevron_up :if={row.expanded} mini={true} class={"h-5 w-5 " <> class}/>
            <Heroicons.chevron_down :if={not row.expanded} mini={true} class={"h-5 w-5 " <> class}/>
          </td>

          <td :for={field_slot <- @field_slots} class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-6">
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
              <% {_has_prev, _has_next, pages} = generate_pages(@page_idx, @page_size, @total_results) %>
              <nav class="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
                <a :if={@has_prev} phx-click="change-page" phx-target={@target} phx-value-page={@page_idx - 1} class="relative inline-flex items-center rounded-l-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 hover:cursor-pointer focus:z-20">
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

                <a :if={@has_next} phx-click="change-page" phx-target={@target} phx-value-page={@page_idx + 1} class="relative inline-flex items-center rounded-r-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 hover:cursor-pointer focus:z-20">
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

  defp op_options_and_default(_spec, nil), do: {[], ""}
  defp op_options_and_default(spec, field_value) do
    atom_field = String.to_existing_atom(field_value)
    filter_data = Enum.find(spec.filterable_columns, & &1.col_id == atom_field)

    if filter_data == nil do
      {[], ""}
    else
      type_map = spec.filter_types[filter_data[:type]] || %{}
      ops = type_map[:ops] || []
      kvs = Enum.map(ops, fn {filter_id, filter_name} -> {filter_name, filter_id} end)

      default_selected = case ops do
        [] -> ""
        [{id, _} | _] -> id
      end

      {kvs, default_selected}
    end
  end


  attr :form, :any
  attr :target, :any
  attr :spec, :any

  attr :filters_default_field, :any
  attr :filterable_fields, :any

  defp filters_form(assigns) do
    ~H"""
    <.form for={@form} phx-target={@target} phx-change="filters-change" phx-submit="filters-change" class="flex flex-warp items-center">

      <.inputs_for :let={filter} field={@form[:filters]}>
        <div class="overflow-hidden m-1 inline-flex items-center rounded-full border pr-2 text-sm font-medium text-gray-900 h-8 border-gray-200 bg-white">
          <input type="hidden" name="filters[filters_sort][]" value={filter.index}/>

          <% field = filter[:field] %>
          <% selected_field = field.value || @filters_default_field %>
          <select id={field.id} name={field.name} class="border-none p-0 pl-4 pr-4 h-full text-inherit text-sm font-medium appearance-none bg-none cursor-pointer hover:bg-gray-200 focus:ring-0 focus:bg-gray-200 bg-transparent">
            <%= Phoenix.HTML.Form.options_for_select(
              Enum.map(@filters_fields, &{&1.name, &1.id_str}),
              selected_field
            ) %>
          </select>

          <% op = filter[:op] %>
          <select id={op.id} name={op.name} class="border-none p-0 pl-4 pr-4 h-full text-inherit text-sm font-medium appearance-none bg-none cursor-pointer hover:bg-gray-200 focus:ring-0 focus:bg-gray-200 text-center bg-transparent">
            <% {options, default_selected} = op_options_and_default(@spec, selected_field) %>
            <% selected_op = op.value || default_selected %>
            <%= Phoenix.HTML.Form.options_for_select(options, selected_op) %>
          </select>

          <% value = filter[:value] %>
          <input type="text" id={value.id} name={value.name} value={value.value} class="text-sm font-medium border-none pl-2 pr-2 h-full focus:outline-0 bg-transparent"/>

          <label class="ml-1 inline-flex h-4 w-4 flex-shrink-0 rounded-full p-1 text-gray-400 hover:bg-gray-200 hover:text-gray-500 cursor-pointer">
            <input type="checkbox" name="filters[filters_drop][]" value={filter.index} class="hidden" />
            <svg class="h-2 w-2" stroke="currentColor" fill="none" viewBox="0 0 8 8">
              <path stroke-linecap="round" stroke-width="1.5" d="M1 1l6 6m0-6L1 7" />
            </svg>
          </label>
        </div>
      </.inputs_for>

      <label class="m-1 inline-flex items-center rounded-full border border-gray-200 bg-white p-2 text-gray-400 cursor-pointer hover:bg-gray-200 hover:text-gray-500">
        <input type="checkbox" name="filters[filters_sort][]" class="hidden"/>
        <Heroicons.plus class="w-4 h-4"/>
      </label>

    </.form>
    """
  end

end
