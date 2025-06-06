defmodule DataTable.Ecto.Query do
  @moduledoc """
  DSL used to declare queries for use with the `DataTable.Ecto` source.

  ```elixir
  def mount(_params, _session, socket) do
    query = DataTable.Ecto.Query.from(
      user in MyApp.User,
      fields: %{
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name
      },
      key: :id,
      default_order_by: user.id
    )

    socket = assign(socket, :source_query, query)

    [...]
  end
  ```

  For a description of the differences between `Ecto.Query.from/2` and `from/2`,
  see the docs of `from/2`.

  ## On joins and complex queries
  Since `field`s are only actually requested from the Database when a column
  in the `DataTable` actually needs them, you can make your query join several
  tables and only pay the price when the columns actually are rendered.

  This is very useful for admin interfaces where you want to make many pieces of
  information available, but not necessarily need them shown by default.

  As an example, in a query like:
  ```elixir
  DataTable.Ecto.Query.from(
    article in Model.Article,
    left_join: category in assoc(article, :category),
    left_join: user in assoc(article, :author),
    fields: %{
      title: article.title,
      body: article.body,
      category_name: category.name,
      author_name: author.name
    },
    key: :id
  )
  ```

  As long as the columns in your table which use `category` and `author_name` are not
  visible, those will not be fetched by the database, and the database will likely not
  even bother doing the joins in its query plan.

  The same also applies to subqueries, aggregations, etc. You should not be scared of
  including optional columns in your table for admin interfaces.
  """

  defstruct [
    base: nil,
    fields: %{},
    key: nil,
    filters: [],
    default_order_by: nil
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
  Functions exactly like `Ecto.Query.from/2`, but with some minor differences:

  * `:select` and `:select_merge` are not accepted.
    * `:fields` is used instead.
  * `:key` is required. `:key` should be the name of a field which uniquely
    identifies each row.
  * `:order_by` is not accepted, as ordering is determined by the user when
    using the table.
    * `:default_order_by` can be used to specify a default.

  # Arguments

  ## `:fields` argument
  Used to indicate which fields are fetchable by the table.

  Let's compare it to `Ecto.Query.from/2`s `:select`:
  * `:fields` fetch data only when the  `DataTable` requests the field.
    * `:select` always fetches data.
  * `:fields` can only be a map as the root.
    * `:select` is more flexible with the structures you can return.

  ## `:key` argument
  The `:key` argument is always required, and is used to specify a key in
  `:fields` which uniquely identitifes the row.

  ## `:default_order_by` argument
  Specifies a ordering which is overridden when the `DataTable` explicitly
  sets a sort.
  """
  defmacro from(expr, kw \\ []) do
    require Ecto.Query

    fields = Keyword.fetch!(kw, :fields)
    key = Keyword.fetch!(kw, :key)
    default_order_by = Keyword.get(kw, :default_order_by)

    filters =
      Keyword.fetch!(kw, :filters)
      |> unescape_literal(__CALLER__)

    kw = Keyword.drop(kw, [:fields, :key, :filters, :default_order_by])

    if Keyword.has_key?(kw, :select) do
      Ecto.Query.Builder.error!("`:select` key is not supported in `DataTable.Ecto.from/2`. Use `:fields` instead.")
    end
    if Keyword.has_key?(kw, :select_merge) do
      Ecto.Query.Builder.error!("`:select_merge` key is not supported in `DataTable.Ecto.from/2`. Use `:fields` instead.")
    end
    if Keyword.has_key?(kw, :order_by) do
      Ecto.Query.Builder.error!("`:order_by` key will override table sorts when used in a DataTable query. Use `:default_order_by` instead.")
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

    fields_dyn_map = process_fields(binds_expr, fields)
    order_by = process_order_by(binds_expr, default_order_by)

    quote do
      require Ecto.Query
      %DataTable.Ecto.Query{
        base: Ecto.Query.from(unquote(expr), unquote(kw)),
        fields: unquote(fields_dyn_map),
        key: unquote(key),
        filters: unquote(Macro.escape(filters)),
        default_order_by: unquote(order_by)
      }
    end
  end

  defmacro fields(query, binding \\ [], expr) do
    fields = process_fields(binding, expr)

    quote do
      fields = unquote(fields)
      case unquote(query) do
        query = %DataTable.Ecto.Query{fields: nil} -> %{query | fields: fields}
        %DataTable.Ecto.Query{} -> raise "`:fields` already set in `DataTable.Ecto.Query`"
        query = %Ecto.Query{} ->
          %DataTable.Ecto.Query{
            base: query,
            fields: fields
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

  defp process_fields(binds, fields) do
    fields =
      case fields do
        {:%{}, _opts, kws} ->
          Enum.each(kws, fn
            {key, _val} when is_atom(key) -> nil
            _ -> Ecto.Query.Builder.error!("`:fields` must only contain literal atom keys")
          end)
          Enum.into(kws, %{})

        _ ->
          Ecto.Query.Builder.error!("`:fields` clause must contain a map")
      end

    fields_dyn_list = Enum.map(fields, fn {name, val} ->
      dyn_val = quote do
        Ecto.Query.dynamic(unquote(binds), unquote(val))
      end
      {name, dyn_val}
    end)

    {:%{}, [], fields_dyn_list}
  end

  @valid_orderings [:asc, :asc_nulls_last, :asc_nulls_first, :desc, :desc_nulls_last, :desc_nulls_first]

  defp process_order_by(_binds, nil) do
    quote do
      []
    end
  end
  defp process_order_by(_binds, {:^, _opts, [inner]}) do
    inner
  end
  defp process_order_by(_binds, expr) when is_atom(expr) do
    quote do
      [{:asc, unquote(expr)}]
    end
  end
  defp process_order_by(binds, expr) when is_list(expr) do
    Enum.map(expr, fn
      {dir, field} when dir in @valid_orderings and is_atom(field) ->
        Macro.escape({dir, field})

      {dir, val} when dir in @valid_orderings ->
        quote do
          {unquote(dir), Ecto.Query.dynamic(unquote(binds), unquote(val))}
        end

      field when is_atom(field) ->
        Macro.escape({:asc, field})

      val ->
        quote do
          {:asc, Ecto.Query.dynamic(unquote(binds), unquote(val))}
        end
    end)
  end
  defp process_order_by(binds, expr) do
    quote do
      [{:asc, Ecto.Query.dynamic(unquote(binds), unquote(expr))}]
    end
  end

end
