defmodule DataTable.Util do
    import Ecto.Query

    if Code.ensure_loaded?(Ecto) do

      def query_filter(query, filter = %{op: "="}) do
        where(query, [v], field(v, ^filter.field) == ^filter.value)
      end
      def query_filter(query, filter = %{op: ">"}) do
        where(query, [v], field(v, ^filter.field) > ^filter.value)
      end
      def query_filter(query, filter = %{op: ">="}) do
        where(query, [v], field(v, ^filter.field) >= ^filter.value)
      end
      def query_filter(query, filter = %{op: "<"}) do
        where(query, [v], field(v, ^filter.field) == ^filter.value)
      end
      def query_filter(query, filter = %{op: "<="}) do
        where(query, [v], field(v, ^filter.field) <= ^filter.value)
      end
      def query_filter(query, filter = %{op: "contains"}) do
        where(query, [v], fragment("? ILIKE ?", field(v, ^filter.field), ^"%#{filter.value}%"))
      end
      def query_filter(query, filter = %{op: "ilike"}) do
        where(query, [v], fragment("? ILIKE ?", field(v, ^filter.field), ^filter.value))
      end

      def query_filters(query, filters) do
        Enum.reduce(filters, query, &query_filter(&2, &1))
      end

      def query_sort(query, nil) do
        query
      end
      def query_sort(query, {field, dir}) when dir in [:asc, :desc] do
        order_by(query, ^[{dir, field}])
      end

      def query_page(query, page, page_size) do
        offset = page * page_size

        query
        |> offset(^offset)
        |> limit(^page_size)
      end

      def query_params(query, params) do
        base_query = query_filters(query, params.filters)

        results_query =
          base_query
          |> query_sort(params.sort)
          |> query_page(params.page, params.page_size)

        {base_query, results_query}
      end

    end


end
