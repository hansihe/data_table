defmodule DataTable.Components do
  use Phoenix.Component

  attr :state, :atom
  attr :on_toggle, :string, default: nil
  attr :rest, :global

  def checkbox(assigns) do
    ~H"""
    <% base_class = "border-gray-300 border text-primary-700 rounded w-5 h-5 ease-linear transition-all duration-150 cursor-pointer focus:outline focus:outline-offset-2 outline-offset-0" %>
    <% class = case @state do
      true ->
        base_class <> " custom-checkbox-check-bg bg-blue-700"
      :dash ->
        base_class <> " custom-checkbox-dash-bg bg-blue-700"
      false ->
        base_class <> " bg-white"
    end %>

    <% event_attrs = if @on_toggle == nil do
      []
    else
      [
        {:"phx-key", "Enter"},
        {:"phx-keydown", @on_toggle},
        {:"phx-click", @on_toggle},
      ]
    end %>

    <div class={class} tabindex="0" {event_attrs} {@rest}></div>
    """
  end

  slot :inner_block

  def table_container(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
          <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

end
