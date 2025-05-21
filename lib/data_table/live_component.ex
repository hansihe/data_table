defmodule DataTable.LiveComponent do
  @moduledoc false
  use Phoenix.LiveComponent
  alias DataTable.Util.DataDeps

  alias __MODULE__.Filters
  alias __MODULE__.Logic

  @impl true
  def render(assigns) do
    assigns.theme.root(assigns)
  end

  @impl true
  def mount(socket) do
    socket =
      assign(socket, %{
        first: true
      })

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    first = socket.assigns[:first] != false

    socket = assign(socket, :target, socket.assigns.myself)

    data_deps =
      if first do
        DataDeps.new(socket)
        |> Logic.init()
      else
        DataDeps.new(socket)
      end

    socket =
      data_deps
      # `assign_input` performs change tracking, which means
      # that the fields will only be marked as changed if they
      # actually are.
      # This changed mark is what drives updates throughout the
      # `compute` function, logic will only be run if relevant
      # inputs have changed.
      |> DataDeps.assign_input(:id, assigns.id)
      |> DataDeps.assign_input(:source, assigns.source)
      |> DataDeps.assign_input(:theme, assigns.theme)
      |> DataDeps.assign_input(:col, assigns.col)
      |> DataDeps.assign_input(:selection_action, assigns.selection_action)
      |> DataDeps.assign_input(:row_expanded, assigns.row_expanded)
      |> DataDeps.assign_input(:row_buttons, assigns.row_buttons)
      |> DataDeps.assign_input(:top_right, assigns.top_right)
      |> DataDeps.assign_input(:always_columns, assigns[:always_columns] || [])
      |> DataDeps.assign_input(:handle_nav, assigns[:handle_nav])
      |> DataDeps.assign_input(:nav, assigns[:nav])
      |> Logic.compute()
      |> DataDeps.finish()

    socket = assign(socket, :first, false)

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
      DataDeps.new(socket)
      |> DataDeps.assign_input(:shown_fields, shown_fields)
      |> Logic.compute()
      |> DataDeps.finish()

    {:noreply, socket}
  end

  def handle_event("cycle-sort", %{"sort-toggle-id" => field_str}, socket) do
    # TODO validate further. Not a security issue, but nice to have.
    field = String.to_existing_atom(field_str)

    socket =
      DataDeps.new(socket)
      |> DataDeps.assign_input(:sort, cycle_sort(socket.assigns.sort, field))
      |> Logic.compute()
      |> DataDeps.finish()

    # |> dispatch_handle_nav()

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
      DataDeps.new(socket)
      |> DataDeps.assign_input(:expanded, expanded)
      |> Logic.compute()
      |> DataDeps.finish()

    {:noreply, socket}
  end

  def handle_event("change-page", %{"page" => page}, socket) do
    socket =
      DataDeps.new(socket)
      |> put_page(page)
      |> Logic.compute()
      |> DataDeps.finish()

    # |> dispatch_handle_nav()

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
      DataDeps.new(socket)
      |> DataDeps.assign_input(:selection, selection)
      |> Logic.compute()
      |> DataDeps.finish()

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
      DataDeps.new(socket)
      |> DataDeps.assign_input(:selection, selection)
      |> Logic.compute()
      |> DataDeps.finish()

    {:noreply, socket}
  end

  def handle_event("selection-action", %{"action-idx" => action_idx}, socket) do
    {action_idx, ""} = Integer.parse(action_idx)
    %{action_fn: action_fn} = Enum.fetch!(socket.assigns.selection_actions, action_idx)

    selection = socket.assigns.selection
    action_fn.(selection)

    socket =
      DataDeps.new(socket)
      # TODO clear selection?
      # |> DataDeps.assign_input(:selection, selection)
      |> Logic.compute()
      |> DataDeps.finish()

    {:noreply, socket}
  end

  def handle_event("filters-change", params, socket) do
    static = socket.assigns.static
    filters_changes = params["filters"] || %{}

    changeset =
      %Filters{}
      |> Filters.changeset(static.filter_columns, filters_changes)

    socket =
      DataDeps.new(socket)
      |> DataDeps.assign_input(:filters_changeset, changeset)
      |> Logic.compute()
      |> DataDeps.finish()

    # |> dispatch_handle_nav()

    {:noreply, socket}
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
    DataDeps.assign_input(state, :page, page)
  end

  defp put_page(state, page) when is_integer(page) do
    DataDeps.assign_input(state, :page, page)
  end

  defp field_by_str_id(str_id, socket) do
    id = Map.fetch!(socket.assigns.static.field_id_by_str_id, str_id)
    Map.fetch!(socket.assigns.static.field_by_id, id)
  end
end
