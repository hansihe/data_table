defmodule DataTable.Ecto.Dsl.Verifiers.FragmentOrder do
  use Spark.Dsl.Verifier

  alias DataTable.Ecto.Dsl

  import Spark.Dsl.Verifier

  def verify(state) do
    {failed, _visited_fragments} =
      state
      |> get_entities([:ecto_source])
      |> Enum.filter(fn
        %Dsl.QueryFragment{} -> true
        _ -> false
      end)
      |> Enum.reduce({[], MapSet.new()}, fn fragment, {failed, visited_fragments} ->
        deps = MapSet.new(fragment.depends)

        failed = case MapSet.subset?(deps, visited_fragments) do
          true ->
            failed

          false ->
            entry = {fragment.name, MapSet.difference(deps, visited_fragments)}
            [entry | failed]
        end

        visited_fragments = MapSet.put(visited_fragments, fragment.name)

        {failed, visited_fragments}
      end)

    case failed do
      [] ->
        :ok

      [{fail_fragment, fail_deps} | _] ->
        {:error, "#{fail_fragment} depends on fragments #{inspect(MapSet.to_list(fail_deps))}, but they wheren't defined before it"}
    end
  end

end
