defmodule DataTable.Theme.Basic do
  @moduledoc """
  Bare minimum DataTable theme designed with two purposes in mind:
  * Serve as a bare minimum example for people wanting to develop their own
  * Simple theme for use in tests

  Do not expect anything pretty if you try it yourself. Not expected to
  be very usable.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  alias DataTable.Theme.Util

  def root(assigns) do
    ~H"""
    <div>
      <div class="header">
      </div>
      <table>
        <thead>
          <tr>
            <!-- Checkbox cell is only visible if selection is enabled -->
            <th :if={@static.can_select} class="selection">
              <.checkbox state={@header_selection} on_toggle="toggle-all" phx-target={@target}/>
            </th>

            <!-- Expand/contract cell is only visible if expansion is enabled -->
            <!-- Header row contains nothing. -->
            <th :if={@static.can_expand}></th>

            <!-- Render header cell for each visible column -->
            <th :for={field <- @header_fields} class="column-header">
              <a :if={not field.can_sort}><%= field.name %></a>

              <!-- If the field is sortable, we need to render visual indicator and make clickable. -->
              <a :if={field.can_sort} class="sort-toggle" phx-click="cycle-sort" phx-target={@target} phx-value-sort-toggle-id={field.sort_toggle_id}>
                <%= field.name %>

                <span :if={field.sort == :asc} class="sort-asc">v</span>
                <span :if={field.sort == :desc} class="sort-desc">^</span>
              </a>
            </th>

            <!-- Row buttons cell -->
            <th>
              <!-- TODO top right dropdown -->
            </th>
          </tr>
        </thead>
        <tbody>
          <%= for row <- @rows do %>
            <tr>
              <!-- Checkbox cell is only visible if selection is enabled -->
              <td :if={@static.can_select} class="selection">
                <.checkbox state={row.selected} on_toggle="toggle-row" phx-target={@target} phx-value-id={row.id}/>
              </td>

              <!-- Expand/contract cell is only visible if expansion is enabled -->
              <td :if={@static.can_expand} class="expansion" phx-click={JS.push("toggle-expanded", page_loading: true)} phx-target={@target} phx-value-data-id={row.id}>
                <span :if={row.expanded}>^</span>
                <span :if={not row.expanded}>v</span>
              </td>

              <!-- Render body cell for each visible column -->
              <td :for={field_slot <- @field_slots} class="data-cell">
                <%= render_slot(field_slot, row.data) %>
              </td>

              <!-- Row buttons cell -->
              <td>
                <%= if @static.has_row_buttons do %>
                  <%= render_slot(@static.row_buttons_slot, row.data) %>
                <% end %>
              </td>
            </tr>

            <!-- If the row is expanded, we render an additional row that spans every column. -->
            <!-- This row contains the expanded content. -->
            <tr :if={row.expanded} class="expanded-row-content">
              <td colspan="99999">
                <%= render_slot(@static.row_expanded_slot, row.data) %>
              </td>
            </tr>
          <% end %>
        </tbody>

        <tfoot>
          <tr>
            <td colspan="99999">
              <div class="pagination-desc">
                Showing
                <span class="start"><%= @page_start_item %></span>
                to
                <span class="end"><%= @page_end_item %></span>
                of
                <span class="total"><%= @total_results %></span>
                results
              </div>

              <nav class="pagination-buttons">
                <% pages = Util.generate_pages(@page_idx, @page_size, @total_results) %>

                <a :if={@has_prev} class="prev" phx-click="change-page" phx-value-page={@page_idx - 1} phx-target={@target}>
                  Previous Page
                </a>

                <a :for={{:page, page_num, current} <- pages} class="page" phx-click="change-page" phx-value-page={page_num} phx-target={@target}>
                  <%= page_num + 1 %>
                  <span :if={current}>(current)</span>
                </a>

                <a :if={@has_next} class="next" phx-click="change-page" phx-value-page={@page_idx + 1} phx-target={@target}>
                  Next Page
                </a>
              </nav>
            </td>
          </tr>
        </tfoot>
      </table>
    </div>
    """
  end

  attr :state, :atom
  attr :on_toggle, :string, default: nil
  attr :rest, :global

  def checkbox(assigns) do
    ~H"""
    <% event_attrs = if @on_toggle == nil do
      []
    else
      [
        {:"phx-key", "Enter"},
        {:"phx-keydown", @on_toggle},
        {:"phx-click", @on_toggle},
      ]
    end %>

    <span class="checkbox" tabindex="0" {event_attrs} {@rest}>
      <%= case @state do %>
        <% true -> %>
          "X"
        <% :dash -> %>
          "-"
        <% false -> %>
          "O"
      <% end %>
    </span>
    """
  end

end
