defmodule DataTable.NavState do
  @type t :: %__MODULE__{}

  defstruct [
    set: MapSet.new([:filters, :sort, :page]),
    filters: [],
    sort: nil,
    page: 0,
  ]

  def encode(nav_state) do
    filter_params =
      nav_state.filters
      |> Enum.map(fn {filter, op, value} ->
        {"filter[#{filter}]#{op}", value || ""}
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

  def encode_query_string(nav_state) do
    nav_state
    |> encode()
    |> URI.encode_query()
    |> case do
      "" -> ""
      val -> "?" <> val
    end
  end

  def decode(nav_state \\ %__MODULE__{}, query) do
    components =
      Enum.flat_map(query, fn {k, v} ->
        case {k, Regex.run(~r/^filter\[([^\]]+)\](.+)$/, k)} do
          {_k, [_, field, op]} ->
            [{:filter, {field, op, v}}]

          {"asc", _} ->
            {:sort, {v, :asc}}

          {"desc", _} ->
            {:sort, {v, :desc}}

          {"page", _} ->
            [{:page, v}]

          _ -> []
        end
      end)

    Enum.reduce(components, nav_state, fn
      {:page, page}, s -> %{s | page: page}
      {:sort, sort}, s -> %{s | sort: sort}
      {:filter, filter}, s ->
        %{ s |
          filters: s.filters ++ [filter]
        }
    end)
  end

  def decode_query_string(nav_state \\ %__MODULE__{}, query_string) do
    query_string = case query_string do
      "?" <> str -> str
      str -> str
    end

    query = Enum.to_list(URI.query_decoder(query_string || ""))
    IO.inspect(query)
    decode(nav_state, query)
  end

end
