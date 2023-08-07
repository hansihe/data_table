# DataTable

A flexible DataTable component for LiveView.

Some of the features the component has:
* Filtering
* Sorting
* Expandable rows
* Pagination
* Row selection with customizable bulk actions (R)
* First class Ecto support
* Data is fetched from `DataTable.Source` behaviour, usable with custom data sources (R)
* Support for persisting sort/filter state to query string (R)
* Tailwind theme included, but fully customizable (R)

Rows marked with R are currently undergoing a refactor, and are rough around the edges.

```elixir
def render(assigns) do
  ~H"""
  <DataTable.live_data_table
    id="table"
    source={{DataTable.Ecto, {MyApp.Repo, @source_query}}}>

    <:col :let={row} name="Id" fields={[:id]} sort_field={:id}>
      <%= row.id %>
    </:col>

    <:col :let={row} name="Name" fields={[:first_name, :last_name]}>
      <%= row.first_name <> " " <> row.last_name %>
    </:col>

  </DataTable.live_data_table>
  """
end

def mount(_params, _session, socket) do
  query = DataTable.Ecto.Query.from(
    user in MyApp.User,
    columns: %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name
    },
    key: :id
  )

  socket = assign(socket, :source_query, query)

  [...]
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `data_table` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:data_table, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/data_table>.

# data_table
