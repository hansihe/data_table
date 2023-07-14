defmodule DataTable.NavState do
  alias DataTable.Spec

  @type t :: %__MODULE__{}

  defstruct [
    next_filter_id: 0,
    filters: [],
    sort: nil,
    page: 0,
    expanded: MapSet.new(),
  ]

  def default(spec) do
    %__MODULE__{
      sort: spec.default_sort,
    }
  end

  def filters(nav_state) do
    nav_state.filters
  end

  def put_page(nav_state, page) when is_binary(page) do
    {page, ""} = Integer.parse(page)
    put_page(nav_state, page)
  end
  def put_page(nav_state, page) when is_integer(page) do
    %{nav_state | page: page}
  end

  def put_sort(nav_state, {field, "asc"}, spec), do: put_sort(nav_state, {field, :asc}, spec)
  def put_sort(nav_state, {field, "desc"}, spec), do: put_sort(nav_state, {field, :desc}, spec)
  def put_sort(nav_state, {field, dir}, spec) when dir in [:asc, :desc] do
    %{nav_state | sort: {field, dir}}
  end

  def cycle_sort(nav_state, field, spec) do
    sort = case nav_state.sort do
      {^field, :asc} -> {field, :desc}
      {^field, :desc} -> nil
      _ -> {field, :asc}
    end
    %{nav_state | sort: sort}
  end

  #def add_filter(nav_state, _spec) do
  #  id = nav_state.next_filter_id
  #  nav_state = %{ nav_state |
  #    next_filter_id: id + 1,
  #    filter_order: nav_state.filter_order ++ [id],
  #  }
  #  {id, nav_state}
  #end

  #def set_filter(nav_state, filter_id, filter, _spec) do
  #  %{ nav_state |
  #    filter_state: Map.put(nav_state.filter_state, filter_id, filter),
  #  }
  #end

  #def remove_filter(nav_state, filter_id) do
  #  %{ nav_state |
  #    filter_order: Enum.reject(nav_state.filter_order, &(&1 == filter_id)),
  #    filter_state: Map.delete(nav_state.filter_state, filter_id),
  #  }
  #end

  def encode(nav_state, _spec) do
    filter_params =
      filters(nav_state)
      |> Enum.map(fn filter ->
        {"filter[#{filter.field}]#{filter.op}", filter.value || ""}
      end)

    page_params = if nav_state.page == 0 do
      []
    else
      [{"page", nav_state.page}]
    end

    sort_params = case nav_state.sort do
      nil -> []
      {field, :asc} -> [{"asc", Atom.to_string(field)}]
      {field, :desc} -> [{"desc", Atom.to_string(field)}]
    end

    Enum.concat([
      page_params,
      sort_params,
      filter_params,
    ])
  end

  def decode(nav_state, query, spec) do
    get_id = fn field, inner ->
      case Map.fetch(spec.field_id_by_str_id, field) do
        {:ok, field_id} -> inner.(field_id)
        _ -> []
      end
    end

    components =
      Enum.flat_map(query, fn {k, v} ->
        case {k, Regex.run(~r/^filter\[([^\]]+)\](.+)$/, k)} do
          {_k, [_, field, op]} ->
            #get_id.(field, &[{:filter, %{field: &1, op: op, value: v}}])
            [{:filter, %{field: field, op: op, value: v}}]

          {"asc", _} ->
            get_id.(v, &[{:sort, {&1, :asc}}])

          {"desc", _} ->
            get_id.(v, &[{:sort, {&1, :desc}}])

          {"page", _} ->
            [{:page, v}]

          _ -> []
        end
      end)

    Enum.reduce(components, nav_state, fn
      {:page, page}, s -> put_page(s, page)
      {:sort, sort}, s -> put_sort(s, sort, spec)
      {:filter, filter}, s ->
        %{ s |
          filters: s.filters ++ [filter]
        }
    end)
  end

end
