defmodule DataTable.Ecto.Source do
  @behaviour DataTable.Source

  @impl true
  def query({repo, query}, query_params) do
    require Ecto.Query

    dyn_select =
      query_params.shown_columns
      |> Enum.map(fn col_id ->
        {col_id, Map.fetch!(query.columns, col_id)}
      end)
      |> Enum.into(%{})

    base = Enum.reduce(query_params.filters, query.base, fn filter, acc ->
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

    ecto_query = case query_params.sort do
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
      |> Ecto.Query.offset(^(query_params.page_size * query_params.page))
      |> Ecto.Query.limit(^query_params.page_size)
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

  @impl true
  def filterable_columns({_repo, query}) do
    query.filters
    |> Enum.map(fn {col_id, type} ->
      %{
        col_id: col_id,
        type: type
      }
    end)
  end

  @impl true
  def filter_types({_repo, _query}) do
    %{
      string: %{
        validate: fn _op, _val -> true end,
        ops: [
          contains: "contains",
          eq: "="
        ]
      },
      integer: %{
        validate: fn
          _op, nil ->
            false

          _op, val ->
            case Integer.parse(val) do
              {_, ""} -> true
              _ -> false
            end
        end,
        ops: [
          eq: "=",
          lt: "<",
          gt: ">"
        ]
      },
      boolean: %{
        validate: fn _op, val ->
          case val do
            "true" -> true
            "false" -> true
            _ -> false
          end
        end,
        ops: [
          eq: "="
        ]
      }
    }
  end

  @impl true
  def key({_repo, query}), do: query.key

end
