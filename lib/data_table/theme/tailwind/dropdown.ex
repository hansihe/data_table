defmodule DataTable.Theme.Tailwind.Dropdown do
  @moduledoc false

  use Phoenix.Component
  alias Phoenix.LiveView.JS
  alias DataTable.Theme.Tailwind.Heroicons
  alias DataTable.Theme.Tailwind.Link

  # Customized from https://github.com/petalframework/petal_components/blob/3dc52043661aa02c554fd6f7b163a851cff88566/lib/petal_components/dropdown.ex
  # to simplify dependencies since this is a library.
  # License: MIT (https://github.com/petalframework/petal_components/blob/3dc52043661aa02c554fd6f7b163a851cff88566/LICENSE.md)

  @transition_in_base "transition transform ease-out duration-100"
  @transition_in_start "transform opacity-0 scale-95"
  @transition_in_end "transform opacity-100 scale-100"

  @transition_out_base "transition ease-in duration-75"
  @transition_out_start "transform opacity-100 scale-100"
  @transition_out_end "transform opacity-0 scale-95"

  attr :options_container_id, :string
  attr :label, :string, default: nil, doc: "labels your dropdown option"
  attr :class, :any, default: nil, doc: "any extra CSS class for the parent container"

  attr :menu_items_wrapper_class, :any,
    default: nil,
    doc: "any extra CSS class for menu item wrapper container"

  attr :js_lib, :string, default: "live_view_js"

  attr :placement, :string, default: "left", values: ["left", "right"]
  attr :rest, :global

  slot :trigger_element
  slot :inner_block, required: false

  @doc """
    <.dropdown label="Dropdown" js_lib="alpine_js|live_view_js">
      <.dropdown_menu_item link_type="button">
        <.icon name="hero-home" class="w-5 h-5 text-gray-500" />
        Button item with icon
      </.dropdown_menu_item>
      <.dropdown_menu_item link_type="a" to="/" label="a item" />
      <.dropdown_menu_item link_type="a" to="/" disabled label="disabled item" />
      <.dropdown_menu_item link_type="live_patch" to="/" label="Live Patch item" />
      <.dropdown_menu_item link_type="live_redirect" to="/" label="Live Redirect item" />
    </.dropdown>
  """
  def dropdown(assigns) do
    assigns =
      assigns
      |> assign_new(:options_container_id, fn -> "dropdown_#{Ecto.UUID.generate()}" end)

    ~H"""
    <div
      {@rest}
      {js_attributes("container", @js_lib, @options_container_id)}
      class={[@class, "relative inline-block text-left"]}
    >
      <div>
        <button
          type="button"
          class={trigger_button_classes(@label, @trigger_element)}
          {js_attributes("button", @js_lib, @options_container_id)}
          aria-haspopup="true"
        >
          <span class="sr-only">Open options</span>

          <%= if @label do %>
            <%= @label %>
            <Heroicons.chevron_down solid class="w-5 h-5 ml-2 -mr-1 dark:text-gray-100" />
          <% end %>

          <%= if @trigger_element do %>
            <%= render_slot(@trigger_element) %>
          <% end %>

          <%= if !@label && @trigger_element == [] do %>
            <Heroicons.ellipsis_vertical solid class="h-5 w-5" />
          <% end %>
        </button>
      </div>
      <div
        {js_attributes("options_container", @js_lib, @options_container_id)}
        class={[
          placement_class(@placement),
          @menu_items_wrapper_class,
          "absolute z-30 w-56 mt-2 bg-white rounded-md shadow-lg dark:bg-gray-800 ring-1 ring-black ring-opacity-5 focus:outline-none"
        ]}
        role="menu"
        id={@options_container_id}
        aria-orientation="vertical"
        aria-labelledby="options-menu"
      >
        <div class="py-1" role="none">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  attr :to, :string, default: nil, doc: "link path"
  attr :label, :string, doc: "link label"
  attr :class, :any, default: nil, doc: "any additional CSS classes"
  attr :disabled, :boolean, default: false

  attr :link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"]

  attr :rest, :global, include: ~w(method download hreflang ping referrerpolicy rel target type)
  slot :inner_block, required: false

  def dropdown_menu_item(assigns) do
    ~H"""
    <Link.a
      link_type={@link_type}
      to={@to}
      class={[@class, "flex items-center self-start justify-start w-full gap-2 px-4 py-2 text-sm text-left text-gray-700 transition duration-150 ease-in-out dark:hover:bg-gray-700 dark:text-gray-300 dark:bg-gray-800 hover:bg-gray-100", get_disabled_classes(@disabled)]}
      disabled={@disabled}
      role="menuitem"
      {@rest}
    >
      <%= render_slot(@inner_block) || @label %>
    </Link.a>
    """
  end

  defp trigger_button_classes(nil, []),
    do: "flex items-center text-gray-400 rounded-full hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-100 focus:ring-primary-500"

  defp trigger_button_classes(_label, []),
    do: "inline-flex justify-center w-full px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm dark:text-gray-300 dark:bg-gray-900 dark:hover:bg-gray-800 dark:focus:bg-gray-800 hover:bg-gray-50 focus:outline-none"

  defp trigger_button_classes(_label, _trigger_element),
    do: "align-middle"

  defp js_attributes("container", "live_view_js", options_container_id) do
    hide =
      JS.hide(
        to: "##{options_container_id}",
        transition: {@transition_out_base, @transition_out_start, @transition_out_end}
      )

    %{
      "phx-click-away": hide,
      "phx-window-keydown": hide,
      "phx-key": "Escape"
    }
  end

  defp js_attributes("button", "live_view_js", options_container_id) do
    %{
      "phx-click":
        JS.toggle(
          to: "##{options_container_id}",
          display: "block",
          in: {@transition_in_base, @transition_in_start, @transition_in_end},
          out: {@transition_out_base, @transition_out_start, @transition_out_end}
        )
    }
  end

  defp js_attributes("options_container", "live_view_js", _options_container_id) do
    %{
      style: "display: none;"
    }
  end

  defp placement_class("left"), do: "right-0 origin-top-right"
  defp placement_class("right"), do: "left-0 origin-top-left"

  defp get_disabled_classes(true), do: "text-gray-500 hover:bg-transparent"
  defp get_disabled_classes(false), do: ""
end
