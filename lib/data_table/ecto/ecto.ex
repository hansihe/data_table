defmodule DataTable.Ecto do

  defstruct [
    base_query: nil,
    fragments: [],
    fields: %{}
  ]

  use Spark.Dsl, default_extensions: [extensions: DataTable.Ecto.Dsl]

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

  @doc false
  @impl Spark.Dsl
  def handle_before_compile(_opts) do
    quote bind_quoted: [] do
      @behaviour DataTable.Source

      {:ok, base_query_fn} = Spark.Dsl.Extension.fetch_opt(__MODULE__, [:ecto_source], :query)
      @base_query_fn base_query_fn

      {:ok, query_executor_fn} = Spark.Dsl.Extension.fetch_opt(__MODULE__, [:ecto_source], :execute)
      @query_executor_fn query_executor_fn

      @ecto_source_entities Spark.Dsl.Extension.get_entities(__MODULE__, [:ecto_source])

      @query_fragments @ecto_source_entities
        |> Enum.filter(fn
          %DataTable.Ecto.Dsl.QueryFragment{} -> true
          _ -> false
        end)

      @query_fragment_order Enum.map(@query_fragments, & &1.name)

      @query_fields Spark.Dsl.Extension.get_persisted(__MODULE__, :ecto_source_fields)

      require Ecto.Query

      # Base query function
      case :erlang.fun_info(@base_query_fn)[:arity] do
        0 -> def base_query(_opts), do: @base_query_fn.()
        1 -> def base_query(opts), do: @base_query_fn.(opts)
      end

      # Column builders
      for {_, data} <- @query_fields do
        def build_column(unquote(data.name)) do
          dynamic = Ecto.Query.dynamic(unquote(data.binds), unquote(data.expr))
          data = %{
            stage: :query,
            fragment: unquote(data.fragment),
            dynamic: dynamic,
            filter: unquote(data.filter)
          }
          {:ok, data}
        end
      end
      def build_column(_), do: :error

      # Query fragment order
      def query_fragment_order, do: @query_fragment_order

      # Query fragment dependencies
      for %DataTable.Ecto.Dsl.QueryFragment{name: name, depends: depends} <- @query_fragments do
        def query_fragment_dependencies(unquote(name)), do: {:ok, unquote(Macro.escape(depends))}
      end
      def query_fragment_dependencies(_), do: :error

      # Query fragment applicators
      for %DataTable.Ecto.Dsl.QueryFragment{name: name, query: query_fn} <- @query_fragments do
        @query_fragment_apply query_fn
        case :erlang.fun_info(query_fn)[:arity] do
          1 -> def query_fragment_apply(unquote(name), query, _opts), do: @query_fragment_apply.(query)
          2 -> def query_fragment_apply(unquote(name), query, opts), do: @query_fragment_apply.(query, opts)
        end
      end

      # Query executor
      case :erlang.fun_info(@query_executor_fn)[:arity] do
        1 -> def execute_query(query, _opts), do: @query_executor_fn.(query)
        2 -> def execute_query(query, opts), do: @query_executor_fn.(query, opts)
      end

      @impl DataTable.Source
      def query(query, opts \\ []) do
        DataTable.Ecto.do_query(__MODULE__, query, opts)
      end

    end
  end

end
