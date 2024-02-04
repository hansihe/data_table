defmodule DataTable.TailwindTheme.FiltersFormComponent do
  use Phoenix.LiveComponent

  import DataTable.TailwindTheme

  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} phx-target={@myself} phx-change="change" phx-submit="change" class="py-3 sm:flex items-start">
        <h3 class="text-sm font-medium text-zinc-800 mt-0.5">
          <!-- Filters -->
          <Heroicons.funnel class="w-4"/>
        </h3>

        <!-- <div aria-hidden="true" class="hidden h-5 w-px bg-gray-300 sm:ml-4 sm:block"></div> -->

        <div class="mt-2 sm:mt-0 sm:ml-4">
          <div class="-m-1 flex flex-col space-y-2">
            <.inputs_for :let={filter} field={@form[:filters]}>
              <div class="flex flex-row space-x-2">
                <input
                  type="hidden"
                  name="filters[filters_sort][]"
                  value={filter.index}
                />

                <.select>
                  <option value="a">Name</option>
                  <option value="a">Id</option>
                </.select>
                <.select>
                  <option value="a">contains</option>
                  <option value="a">exactly match</option>
                </.select>
                <.text_input/>
                <.btn_icon>
                  <Heroicons.trash class="w-4"/>
                </.btn_icon>
              </div>
            </.inputs_for>

            <div class="flex flex-row">
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
            <!-- .filters_form
              form={@filters_form}
              target={@target}
              spec={@spec}
              filters_fields={@filters_fields}
              filters_default_field={@filters_default_field} -->
          </div>
        </div>
      </.form>
    </div>
    """
  end

  def mount(socket) do
    socket = assign(socket, :form, to_form(%DataTable.Filters{} |> DataTable.Filters.changeset2(%{})))
    {:ok, socket}
  end

  def handle_event("change", params, socket) do
    IO.inspect(params)
    changeset = DataTable.Filters.changeset2(%DataTable.Filters{}, params["filters"] || %{})
    IO.inspect(changeset)
    socket = assign(socket, :form, to_form(changeset))

    {:noreply, socket}
  end

end
