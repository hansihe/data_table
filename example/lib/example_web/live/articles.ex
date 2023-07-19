defmodule ExampleWeb.ArticlesLive do
  use ExampleWeb, :live_view
  require DataTable.Ecto.Query

  def render(assigns) do
    ~H"""
    <DataTable.live_data_table
      id="table"
      source={{DataTable.Ecto, {Example.Repo, @source_query}}}>

      <:col name="Id" fields={[:id]} sort_field={:id} visible={false} :let={row}>
        <%= row.id %>
      </:col>

      <:col name="Title" fields={[:title]} sort_field={:title} :let={row}>
        <%= row.title %>
      </:col>

    </DataTable.live_data_table>
    """
  end

  def mount(_params, _session, socket) do
    query =
      DataTable.Ecto.Query.from(
        article in Example.Model.Article,
        columns: %{
          id: article.id,
          title: article.title,
          body: article.body
        },
        key: :id,
        filters: %{
          id: :integer,
          title: :string
        }
      )

    socket = assign(socket, %{
      source_query: query
    })

    {:ok, socket}
  end
end
