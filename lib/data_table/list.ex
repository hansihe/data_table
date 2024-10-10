defmodule DataTable.List do
  @moduledoc """
  DataTable source for a native Elixir list.
  """

  @behaviour DataTable.Source

  alias DataTable.Source.{Query, Result}

  @impl true
  def query({list, config}, query) do
    results =
      list
      |> Stream.with_index()
      |> maybe_apply(query.offset, &Stream.drop/2)
      |> maybe_apply(query.limit, &Stream.take/2)
      |> Enum.map(fn {item, idx} -> config.mapper.(item, idx) end)

    %Result{
      results: results,
      total_results: Enum.count(list)
    }
  end

  @impl true
  def filterable_columns({_list, _config}) do
    []
  end

  @impl true
  def filter_types({_list, _config}) do
    %{}
  end

  @impl true
  def key({_list, config}), do: config.key_field

  defp maybe_apply(query, nil, _fun) do
    query
  end

  defp maybe_apply(query, val, fun) do
    fun.(query, val)
  end

end
