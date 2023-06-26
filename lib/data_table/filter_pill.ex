defmodule DataTable.FilterPill do
  use Phoenix.LiveComponent
  import Phoenix.Component
  import Ecto.Changeset, only: [get_field: 2]

  @type_ops %{
    string: [:eq, :lt, :gt, :contains],
    number: [:eq, :lt, :gt],
    boolean: [:eq],
  }

  @changeset_schema %{
    field: :string,
    op: :string,
    value: :string,
  }

  def render(assigns) do
    ~H"""
    <span class={"overflow-hidden m-1 inline rounded-full border pr-2 text-sm font-medium text-gray-900 h-8 " <> if assigns.changeset.valid?, do: "border-gray-200 bg-white", else: "bg-red-50 border-red-500"}>
      <.form :let={f} for={@changeset} as={:filter} id={@id} class="h-full flex items-center" phx-change="change" phx-target={@myself}>

        <!--
        <%= Phoenix.HTML.Form.select f, :field,
            Enum.map(@spec.filterable_fields, &{@spec.field_by_id[&1].name, Atom.to_string(&1)}),
            selected: get_field(@changeset, :field),
            class: "border-none p-0 pl-4 pr-4 h-full text-inherit text-sm font-medium appearance-none bg-none cursor-pointer rounded-full hover:bg-gray-200 focus:ring-0 focus:bg-gray-200 bg-transparent" %>
        -->

        <% selected_field_id = get_field(@changeset, :field) %>
        <select id={@id <> "_field"} name="filter[field]" class="border-none p-0 pl-4 pr-4 h-full text-inherit text-sm font-medium appearance-none bg-none cursor-pointer hover:bg-gray-200 focus:ring-0 focus:bg-gray-200 bg-transparent">
          <%= for field_id <- @spec.filterable_fields do %>
            <% name = @spec.field_by_id[field_id].name %>
            <%= if selected_field_id == Atom.to_string(field_id) do %>
              <option value={Atom.to_string(field_id)} selected><%= name %></option>
            <% else %>
              <option value={Atom.to_string(field_id)}><%= name %></option>
            <% end %>
          <% end %>
        </select>

        <% field_name = get_field(@changeset, :field) %>
        <%= if field_name do %>
          <% field_id = Map.fetch!(@spec.field_id_by_str_id, field_name) %>
          <% field_spec = Map.fetch!(@spec.field_by_id, field_id) %>
          <% field_type = field_spec.filter_type %>
          <% type_spec = Map.fetch!(@spec.field_types, field_type) %>

          <div class="block h-4 w-px bg-gray-300"/>

          <%= Phoenix.HTML.Form.select f, :op,
              Enum.map(type_spec.ops, &{&1, &1}),
              class: "border-none p-0 pl-4 pr-4 h-full text-inherit text-sm font-medium appearance-none bg-none cursor-pointer hover:bg-gray-200 focus:ring-0 focus:bg-gray-200 text-center bg-transparent" %>

          <div class="block h-4 w-px bg-gray-300"/>

          <%= case type_spec[:input_type] || :text do %>
            <% :text -> %>
              <%= Phoenix.HTML.Form.text_input f, :value,
                  placeholder: "value",
                  class: "text-sm font-medium border-none pl-2 pr-2 h-full focus:outline-0 bg-transparent" %>

            <% :integer -> %>
              <%= Phoenix.HTML.Form.number_input f, :value,
                  placeholder: "number",
                  class: "text-sm font-medium border-none pl-2 pr-2 h-full focus:outline-0 bg-transparent" %>
          <% end %>

        <% end %>

        <%= if @changeset.valid? do %>
          <button phx-click="cancel-filter" phx-target={@myself} type="button" class="ml-1 inline-flex h-4 w-4 flex-shrink-0 rounded-full p-1 text-gray-400 hover:bg-gray-200 hover:text-gray-500">
            <svg class="h-2 w-2" stroke="currentColor" fill="none" viewBox="0 0 8 8">
              <path stroke-linecap="round" stroke-width="1.5" d="M1 1l6 6m0-6L1 7" />
            </svg>
          </button>
        <% else %>
          <button phx-click="cancel-filter" phx-target={@myself} type="button" class="ml-1 inline leading-4 h-4 w-4 flex-shrink-0 rounded-full text-center align-middle text-red-500 hover:bg-red-200">
            !
          </button>
        <% end %>
      </.form>
    </span>
    """
  end

  def changeset(data, socket, params) do
    spec = socket.assigns.spec

    changeset =
      {data, @changeset_schema}
      |> Ecto.Changeset.cast(params, [:field, :op, :value])
      |> Ecto.Changeset.validate_required([:field, :op, :value])
      |> Ecto.Changeset.validate_inclusion(:field, Enum.map(spec.filterable_fields, &Atom.to_string(&1)))

    field_error = Keyword.get(changeset.errors, :field)
    if field_error == nil do
      field_id = Map.fetch!(spec.field_id_by_str_id, get_field(changeset, :field))
      field_data = Map.fetch!(spec.field_by_id, field_id)
      type_data = spec.field_types[field_data.filter_type]

      changeset
      |> Ecto.Changeset.validate_required([:op])
      |> Ecto.Changeset.validate_inclusion(:op, type_data.ops)
    else
      changeset
    end
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    spec = assigns.spec
    socket =
      socket
      |> assign(:spec, spec)
      |> assign(:cancel_filter, assigns.cancel_filter)
      |> assign(:change_filter, assigns.change_filter)
      |> assign(:id, assigns.id)

    first_filterable = spec.field_by_id[hd(spec.filterable_fields)]
    first_filter_type = spec.field_types[first_filterable.filter_type]
    first_op = hd(first_filter_type.ops)
    default_state = %{field: Atom.to_string(first_filterable.id), op: first_op, value: nil}

    state = assigns[:state] || %{}
    changeset = changeset(default_state, socket, state)

    socket = assign(socket, :changeset, changeset)

    {:ok, socket}
  end

  def handle_event("cancel-filter", _params, socket) do
    if socket.assigns[:cancel_filter] do
      socket.assigns.cancel_filter.()
    end
    {:noreply, socket}
  end

  def handle_event("change", %{"filter" => params}, socket) do
    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.apply_changes()
      |> changeset(socket, params)

    data = Ecto.Changeset.apply_changes(changeset)
    socket.assigns.change_filter.(data, changeset.valid?)

    socket =
      socket
      |> assign(:changeset, changeset)

    {:noreply, socket}
  end

end
