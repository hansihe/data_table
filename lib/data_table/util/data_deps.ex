defmodule DataTable.Util.DataDeps do
  # For assign
  use Phoenix.LiveView
  # import Phoenix.LiveView, only: [assign: 3, assign: 2]

  defstruct socket: nil, changed: MapSet.new(), derived: %{}

  def new(socket) do
    %__MODULE__{
      socket: socket
    }
  end

  def finish(data_deps) do
    data_deps.socket
  end

  def action(deps, field, value) do
    %{
      deps
      | derived: Map.put(deps.derived, field, value),
        changed: MapSet.put(deps.changed, field)
    }
  end

  # TODO this check is already performed internally, can we
  # avoid doing it twice?
  def assign_input(deps, field, value) do
    case deps.socket.assigns do
      %{^field => ^value} ->
        deps

      _ ->
        %{
          deps
          | socket: assign(deps.socket, field, value),
            changed: MapSet.put(deps.changed, field)
        }
    end
  end

  # def derive(deps, in_fields, fun) do
  #  in_fields = MapSet.new(in_fields)

  #  if MapSet.disjoint?(deps.changed, in_fields) do
  #    deps
  #  else
  #    in_assigns = Map.take(Map.merge(deps.derived, deps.socket.assigns), in_fields)
  #    new_derives = fun.(in_assigns)
  #    derived = Map.merge(deps.derived, new_derives)
  #    changed = MapSet.union(deps.changed, MapSet.new(new_assigns, fn {k, _v} -> k end))

  #    %{
  #      deps
  #      | derived: derived,
  #        changed: changed
  #    }
  #  end
  # end

  def assign_derive(deps, in_fields, tap_fields \\ [], fun) do
    if MapSet.disjoint?(deps.changed, MapSet.new(in_fields)) do
      deps
    else
      in_assigns =
        Map.merge(deps.derived, deps.socket.assigns)
        |> Map.take(tap_fields ++ in_fields)

      new_assigns = fun.(in_assigns)
      socket = assign(deps.socket, new_assigns)
      changed = MapSet.union(deps.changed, MapSet.new(new_assigns, fn {k, _v} -> k end))

      %{
        deps
        | socket: socket,
          changed: changed
      }
    end
  end
end
