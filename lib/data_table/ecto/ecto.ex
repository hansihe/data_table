defmodule DataTable.Ecto do

  defstruct [
    base_query: nil,
    fragments: [],
    fields: %{}
  ]

  @doc false
  def do_query(module, in_query, opts) do
    require Ecto.Query

    selected_columns = MapSet.new(in_query.columns)

    filter_columns =
      in_query.filters
      |> Enum.map(fn {_op, field, _value} -> field end)
      |> MapSet.new()

    sort_column = case in_query.sort do
      nil -> []
      {_dir, column} -> [column]
    end

    # Get data for all columns in query
    column_data =
      Enum.concat([
        selected_columns,
        filter_columns,
        sort_column
      ])
      |> Enum.map(fn column ->
        {:ok, data} = module.build_column(column)
        {column, data}
      end)
      |> Enum.into(%{})

    # Get the set of fragments that should be included in the query.
    # This includes dependencies.
    fragments =
      column_data
      |> Map.values()
      |> Enum.map(& &1.fragment)
      |> MapSet.new()
      |> expand_fragments_set(module)

    # Fragments must be applied in the correct order since fragments
    # can depend on each other.
    # Get the predetermined fragment order and filter that on our
    # set of fragments in the current query.
    fragments_order =
      module.query_fragment_order()
      |> Enum.filter(&MapSet.member?(fragments, &1))

    # Construct the map that will become our select clause.
    ecto_select_columns =
      selected_columns
      |> Enum.map(&{&1, Map.fetch!(column_data, &1).dynamic})
      |> Enum.into(%{})

    # Base query
    query = module.base_query(opts)

    # Apply fragments in order
    query = Enum.reduce(fragments_order, query, fn fragment, query ->
      module.query_fragment_apply(fragment, query, opts)
    end)

    # Filters
    filtered_query = Enum.reduce(in_query.filters, query, fn {op, col_name, value}, query ->
      col_data = Map.fetch!(column_data, col_name)
      col_dyn = col_data.dynamic

      case {op, col_data.filter} do
        {:eq, _} ->
          Ecto.Query.where(query, ^col_dyn == ^value)
        {:ne, _} ->
          Ecto.Query.where(query, ^col_dyn != ^value)
        {:lt, _} ->
          Ecto.Query.where(query, ^col_dyn < ^value)
        {:lte, _} ->
          Ecto.Query.where(query, ^col_dyn <= ^value)
        {:gt, _} ->
          Ecto.Query.where(query, ^col_dyn > ^value)
        {:gte, _} ->
          Ecto.Query.where(query, ^col_dyn >= ^value)
        #{:contains, :string} ->
        #  Ecto.Query.where(query, ^col_dyn)
      end
    end)

    # Sort
    query =
      case in_query.sort do
        nil ->
          filtered_query

        {dir, column} ->
          col_data = Map.fetch!(column_data, column)
          Ecto.Query.order_by(filtered_query, ^[{dir, col_data.dynamic}])
      end

    # # Pagination
    query =
      query
      |> Ecto.Query.offset(^in_query.offset)
      |> Ecto.Query.limit(^in_query.limit)

    # Select columns
    query = Ecto.Query.select(query, ^ecto_select_columns)

    results = module.execute_query(query, opts)
    [count] =
      filtered_query
      |> Ecto.Query.select(count())
      |> module.execute_query(opts)

    %{
      results: results,
      total_results: count
    }
  end

  # Expands the set of fragment to include dependencies.
  defp expand_fragments_set(fragments, module) do
    new_fragments =
      Enum.reduce(fragments, fragments, fn
        nil, acc ->
          acc

        fragment, acc ->
          {:ok, deps} = module.query_fragment_dependencies(fragment)
          MapSet.union(acc, MapSet.new(deps))
      end)

    if new_fragments == fragments do
      fragments
    else
      expand_fragments_set(new_fragments, module)
    end
  end

end
