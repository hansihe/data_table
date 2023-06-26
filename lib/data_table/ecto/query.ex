defmodule DataTable.Ecto.Query do

  defstruct [
    base: nil,
    columns: %{},
    key: nil,
    filters: []
  ]

  defp unescape_literal(ast, env) do
    ast
    |> Macro.expand_literals(env)
    |> unescape_literal_rec()
  end

  defp unescape_literal_rec({:%{}, _opts, kvs}) do
    kvs
    |> Enum.map(fn {key, value} ->
      key = unescape_literal_rec(key)
      value = unescape_literal_rec(value)
      {key, value}
    end)
    |> Enum.into(%{})
  end

  defp unescape_literal_rec([_ | _] = list) do
    list
    |> Enum.map(fn value ->
      unescape_literal_rec(value)
    end)
  end

  defp unescape_literal_rec(term) when is_atom(term), do: term


  @joins [:join, :inner_join, :cross_join, :cross_lateral_join, :left_join, :right_join, :full_join,
          :inner_lateral_join, :left_lateral_join]

  @doc """
  Functions exactly like `Ecto.Query.from/2`, but with some minor modifications:
   * The `:columns` key is used instead of `select` and `select_merge`
   * `select` and `select_merge` are not accepted
   * You can specify which column will be used as the id using the `:id` keyword
   * Filterable columns are specified using `filters`

  ## Filters
  """
  defmacro from(expr, kw \\ []) do
    require Ecto.Query

    columns = Keyword.fetch!(kw, :columns)
    key = Keyword.fetch!(kw, :key)

    filters =
      Keyword.fetch!(kw, :filters)
      |> unescape_literal(__CALLER__)

    kw = Keyword.drop(kw, [:columns, :key, :filters])

    if Keyword.has_key?(kw, :select) do
      Ecto.Query.Builder.error!("`:select` key is not supported in `DataTable.Ecto.from/2`. Use `:columns` instead.")
    end
    if Keyword.has_key?(kw, :select_merge) do
      Ecto.Query.Builder.error!("`:select_merge` key is not supported in `DataTable.Ecto.from/2`. Use `:columns` instead.")
    end

    # Binds from base from
    {_, binds} = Ecto.Query.Builder.From.escape(expr, __CALLER__)

    # Binds from joins
    {binds, _num_binds} = Enum.reduce(kw, {binds, Enum.count(binds)}, fn
      {join, join_expr}, {binds, num_binds} when join in @joins ->
        {:in, _opts1, [{var, _opts2, nil}, _rhs]} = join_expr
        binds = [{var, num_binds} | binds]
        num_binds = num_binds + 1
        {binds, num_binds}

      _, acc ->
        acc
    end)

    binds_expr =
      binds
      |> Enum.sort_by(fn {_var, num} -> num end)
      |> Enum.map(fn {var, _num} -> var end)
      |> Enum.map(fn var -> {var, [], nil} end)

    columns_dyn_map = process_columns(binds_expr, columns)

    quote do
      require Ecto.Query
      %DataTable.Ecto.Query{
        base: Ecto.Query.from(unquote(expr), unquote(kw)),
        columns: unquote(columns_dyn_map),
        key: unquote(key),
        filters: unquote(Macro.escape(filters))
      }
    end
  end

  defmacro columns(query, binding \\ [], expr) do
    columns = process_columns(binding, expr)

    quote do
      columns = unquote(columns)
      case unquote(query) do
        query = %DataTable.Ecto.Query{columns: nil} -> %{query | columns: columns}
        %DataTable.Ecto.Query{} -> raise "`:columns` already set in `DataTable.Ecto.Query`"
        query = %Ecto.Query{} ->
          %DataTable.Ecto.Query{
            base: query,
            columns: columns
          }
      end
    end
  end

  defmacro key(query, key_field) do
    quote do
      key = unquote(key_field)
      case unquote(query) do
        query = %DataTable.Ecto.Query{key: nil} -> %{query | key: key}
        %DataTable.Ecto.Query{} -> raise "`:key` already set in `DataTable.Ecto.Query`"
        query = %Ecto.Query{} ->
          %DataTable.Ecto.Query{
            base: query,
            key: key
          }
      end
    end
  end

  defmacro filters(query, filters) do
    quote do
      filters = unquote(filters)
      case unquote(query) do
        query = %DataTable.Ecto.Query{filters: []} -> %{query | filters: filters}
        %DataTable.Ecto.Query{} -> raise "`:filters` already set in `DataTable.Ecto.Query`"
        query = %Ecto.Query{} ->
          %DataTable.Ecto.Query{
            base: query,
            filters: filters
          }
      end
    end
  end

  defp process_columns(binds, columns) do
    columns =
      case columns do
        {:%{}, _opts, kws} ->
          Enum.each(kws, fn
            {key, _val} when is_atom(key) -> nil
            _ -> Ecto.Query.Builder.error!("`:columns` must only contain literal atom keys")
          end)
          Enum.into(kws, %{})

        _ ->
          Ecto.Query.Builder.error!("`:columns` clause must contain a map")
      end

    columns_dyn_list = Enum.map(columns, fn {name, val} ->
      dyn_val = quote do
        Ecto.Query.dynamic(unquote(binds), unquote(val))
      end
      {name, dyn_val}
    end)

    {:%{}, [], columns_dyn_list}
  end

end
