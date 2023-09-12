defmodule DataTable.Source do
  alias __MODULE__.{Query, Result}

  @type opts :: any()

  @callback query(query :: Query.t(), opts :: opts()) :: Result.t()

  def query({DataTable.Ecto, {repo, query}}, params) do
    require Ecto.Query

    dyn_select =
      params.shown_columns
      |> Enum.map(fn col_id ->
        {col_id, Map.fetch!(query.columns, col_id)}
      end)
      |> Enum.into(%{})

    base = Enum.reduce(params.filters, query.base, fn filter, acc ->
      filter_type = Map.fetch!(query.filters, filter.field)
      field_dyn = Map.fetch!(query.columns, filter.field)

      value = case filter_type do
        :integer ->
          {value, ""} = Integer.parse(filter.value)
          value
        :string ->
          filter.value || ""
        :boolean ->
          filter.value == "true"
      end

      where_dyn = case {filter_type, filter.op} do
        {_, :eq} -> Ecto.Query.dynamic(^field_dyn == ^value)
        {_, :lt} -> Ecto.Query.dynamic(^field_dyn < ^value)
        {_, :gt} -> Ecto.Query.dynamic(^field_dyn > ^value)
        {:string, :contains} -> Ecto.Query.dynamic(like(^field_dyn, ^"%#{String.replace(value, "%", "\\%")}%"))
      end

      Ecto.Query.where(acc, ^where_dyn)
    end)

    ecto_query = case params.sort do
      {field, dir} ->
        field_dyn = Map.fetch!(query.columns, field)
        Ecto.Query.order_by(base, ^[{dir, field_dyn}])
      nil ->
        base
    end

    ecto_query = case query.default_order_by do
      [] ->
        ecto_query
      order_by ->
        Ecto.Query.order_by(ecto_query, ^order_by)
    end

    ecto_query =
      ecto_query
      |> Ecto.Query.offset(^(params.page_size * params.page))
      |> Ecto.Query.limit(^params.page_size)
      |> Ecto.Query.select(^dyn_select)

    # we use a subquery to avoid the count query from being affected
    # by any group_by clauses in the base query. If the base query has a group_by clause,
    # we want to return the number of groups, not the count of each group.
    import Ecto.Query

    count_query = from(
      subquery in subquery(base),
      select: count(subquery)
    )

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
          eq: "=",
          contains: "contains"
        ]
      },
      integer: %{
        ops: [
          eq: "=",
          lt: "<",
          gt: ">"
        ]
      },
      boolean: %{
        ops: [
          eq: "="
        ]
      }
    }
  end

  def key({DataTable.Ecto, {_repo, query}}), do: query.key

end
