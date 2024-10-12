# DataTable

[Docs](https://hexdocs.pm/data_table/DataTable.html)

A flexible DataTable component for LiveView.

![Screenshot of simple DataTable usage](screenshot.png "Simple DataTable usage")
[Source code for the screenshot above. You get all of this in ~50loc.](https://github.com/hansihe/data_table/blob/main/example/lib/example_web/live/articles.ex)

Some of the features the component has:
* Filtering
* Sorting
* Expandable rows
* Pagination
* Row selection with customizable bulk actions
* Data is fetched from `DataTable.Source` behaviour, usable with custom data sources
* First class Ecto `Source`
* Support for persisting sort/filter state to query string
* Tailwind theme included, but fully customizable

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
    fields: %{
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
First you need to add `data_table` to your `mix.exs`:

```elixir
defp deps do
  [
    {:data_table, "~> 1.0}
  ]
end
```

If you want to use the default `Tailwind` theme, you need to set up `tailwind` to include styles
from the `data_table` dependency.

Add this to the `content` list in your `assets/tailwind.js`:
```js
"../deps/data_table/**/*.*ex"
```
