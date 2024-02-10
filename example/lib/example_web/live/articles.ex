defmodule ExampleWeb.ArticlesLive do
  use ExampleWeb, :live_view
  require DataTable.Ecto.Query

  def render(assigns) do
    ~H"""
    <DataTable.live_data_table
      id="table"
      source={{DataTable.Ecto, {Example.Repo, @source_query}}}
      handle_nav={&send(self(), {:nav, &1})}
      nav={@nav}>

      <:col name="Id" fields={[:id]} sort_field={:id} visible={false} :let={row}>
        <%= row.id %>
      </:col>

      <:col name="Title" fields={[:title]} sort_field={:title} filter_field={:title} filter_field_op={:contains} :let={row}>
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

  def handle_info({:nav, nav}, socket) do
    query = DataTable.NavState.encode_query_string(nav)
    socket =
      socket
      |> push_patch(to: "/?" <> query, replace: true)
      |> assign(:nav, nav)
    {:noreply, socket}
  end

  def handle_params(_params, uri, socket) do
    %URI{query: query} = URI.parse(uri)
    IO.inspect(query)
    nav = DataTable.NavState.decode_query_string(query)
    IO.inspect(nav)
    socket = assign(socket, :nav, nav)
    {:noreply, socket}
  end
end
