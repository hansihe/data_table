defmodule DataTable.TestLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <% config = %DataTable.List.Config{} %>
    <% data = Enum.map(0..49, &%{id: &1}) %>

    <DataTable.live_data_table
      id="table"
      theme={DataTable.Theme.Basic}
      source={{DataTable.List, {data, config}}}>

      <:col name="Id" fields={[:id]} sort_field={:id} :let={row}>
        Row <%= row.id %>
      </:col>

      <:row_expanded fields={[:id]} :let={row}>
        Row Expanded <%= row.id %>
      </:row_expanded>

      <:selection_action label="Test Action" handle_action={fn _, _ -> nil end}/>

    </DataTable.live_data_table>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

end
