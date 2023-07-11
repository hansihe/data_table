defmodule DataTable.Source do
  alias __MODULE__.{Query, Result}

  @type opts :: any()

  @callback query(query :: Query.t(), opts :: opts()) :: Result.t()

  def query({DataTable.Ecto, {repo, query}}, params) do
    require Ecto.Query

    IO.inspect(params)

    dyn_select =
      params.shown_columns
      |> Enum.map(fn col_id ->
        {col_id, Map.fetch!(query.columns, col_id)}
      end)
      |> Enum.into(%{})

    ecto_query =
      query.base
      |> Ecto.Query.offset(^(params.page_size * params.page))
      |> Ecto.Query.limit(^params.page_size)
      |> Ecto.Query.select(^dyn_select)

    count_query =
      query.base
      |> Ecto.Query.select(count())

    results = repo.all(ecto_query)
    count = repo.one(count_query)

    %{
      results: results,
      total_results: count
    }
  end

  def filterable_columns({DataTable.Ecto, {_repo, query}}) do
    query.filters
    |> Enum.map(fn {col_id, type} ->
      %{
        col_id: col_id,
        type: type
      }
    end)
  end

  def filter_types({DataTable.Ecto, {_repo, query}}) do
    %{
      string: %{
        ops: [
          eq: "equals"
        ]
      },
      integer: %{
        ops: [
          eq: "equals"
        ]
      }
    }
  end

  def key({DataTable.Ecto, {_repo, query}}), do: query.key

end
