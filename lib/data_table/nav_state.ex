defmodule DataTable.NavState do
  @moduledoc """
  The `NavState` struct contains the navigation state of a `DataTable`.

  The `NavState` can be optionally serialized and deserialized to a query string.

  Contains the following pieces of UI state:
  * Current page
  * Active sort
  * Active filters
  """

  @type t :: %__MODULE__{}

  defstruct [
    set: MapSet.new([:filters, :sort, :page]),
    filters: [],
    sort: nil,
    page: 0,
  ]

  @type kv :: [{key :: String.t(), value :: String.t()}]

  @spec encode(nav_state :: t()) :: kv()
  def encode(nav_state) do
    filter_params =
      nav_state.filters
      |> Enum.map(fn {filter, op, value} ->
        {"filter[#{filter}]#{op}", value || ""}
      end)

    page_params = if nav_state.page == 1 do
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

  @spec encode_query_string(nav_state :: t()) :: String.t()
  def encode_query_string(nav_state) do
    nav_state
    |> encode()
    |> URI.encode_query()
    |> case do
      "" -> ""
      val -> "?" <> val
    end
  end

  @spec decode(base_nav_state :: t(), components :: kv()) :: t()
  def decode(nav_state \\ %__MODULE__{}, query) do
    components =
      Enum.flat_map(query, fn {k, v} ->
        case {k, Regex.run(~r/^filter\[([^\]]+)\](.+)$/, k)} do
          {_k, [_, field, op]} ->
            [{:filter, {field, op, v}}]

          {"asc", _} ->
            field = String.to_existing_atom(v)
            [{:sort, {field, :asc}}]

          {"desc", _} ->
            field = String.to_existing_atom(v)
            [{:sort, {field, :desc}}]

          {"page", _} ->
            case Integer.parse(v) do
              {page, ""} -> [{:page, page}]
              _ -> []
            end

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

  @spec decode_query_string(base_nav_state :: t(), query_string :: String.t()) :: t()
  def decode_query_string(nav_state \\ %__MODULE__{}, query_string) do
    query_string = case query_string do
      "?" <> str -> str
      str -> str
    end

    query = Enum.to_list(URI.query_decoder(query_string || ""))
    decode(nav_state, query)
  end

end
