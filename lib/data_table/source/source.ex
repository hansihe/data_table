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
      |> Ecto.Query.select(^dyn_select)

    results = repo.all(ecto_query)
    #count = repo.one(Ecto.Query.select())

    %{
      results: results,
      total_results: 0
    }
  end

  def key({DataTable.Ecto, {_repo, query}}), do: query.key

end
