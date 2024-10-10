defmodule DataTable.Theme.Tailwind.Heroicons do
  use Phoenix.Component

  # Vendored from https://github.com/mveytsman/heroicons_elixir/blob/afb57ff3e181fbcf55c68ff64a0e7f1d339a07d4/lib/heroicons.ex
  # to simplify dependencies since this is a library.
  # License: MIT (https://github.com/mveytsman/heroicons_elixir/blob/afb57ff3e181fbcf55c68ff64a0e7f1d339a07d4/LICENSE)

  defp svg(assigns) do
    # Not all styles have the micro attribute
    Map.merge(%{micro: false}, assigns)
    |> case do
      %{mini: false, solid: false, micro: false} ->
        ~H"<.svg_outline {@rest}><%= {:safe, @paths[:outline]} %></.svg_outline>"

      %{solid: true, mini: false, micro: false} ->
        ~H"<.svg_solid {@rest}><%= {:safe, @paths[:solid]} %></.svg_solid>"

      %{mini: true, solid: false, micro: false} ->
        ~H"<.svg_mini {@rest}><%= {:safe, @paths[:mini]} %></.svg_mini>"

      %{micro: true, solid: false, mini: false} ->
        ~H"<.svg_micro {@rest}><%= {:safe, @paths[:micro]} %></.svg_micro>"

      %{} ->
        raise ArgumentError, "expected either mini or solid, but got both."
    end
  end

  attr :rest, :global,
    default: %{
      "aria-hidden": "true",
      fill: "none",
      viewBox: "0 0 24 24",
      "stroke-width": "1.5",
      stroke: "currentColor"
    }

  slot :inner_block, required: true

  defp svg_outline(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" {@rest}>
      <%= render_slot(@inner_block) %>
    </svg>
    """
  end

  attr :rest, :global,
    default: %{"aria-hidden": "true", viewBox: "0 0 24 24", fill: "currentColor"}

  slot :inner_block, required: true

  defp svg_solid(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" {@rest}>
      <%= render_slot(@inner_block) %>
    </svg>
    """
  end

  attr :rest, :global,
    default: %{"aria-hidden": "true", viewBox: "0 0 20 20", fill: "currentColor"}

  slot :inner_block, required: true

  defp svg_mini(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" {@rest}>
      <%= render_slot(@inner_block) %>
    </svg>
    """
  end

  attr :rest, :global,
    default: %{"aria-hidden": "true", viewBox: "0 0 16 16", fill: "currentColor"}

  slot :inner_block, required: true

  defp svg_micro(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" {@rest}>
      <%= render_slot(@inner_block) %>
    </svg>
    """
  end

  @doc """
  Renders the `chevron_down` icon.

  By default, the outlined (24x24) component is used, but the `solid`, `mini` or `micro`
  attributes can be provided for alternative styles.

  You may also pass arbitrary HTML attributes to be applied to the svg tag.

  ## Examples

  ```heex
  <Heroicons.chevron_down />
  <Heroicons.chevron_down class="w-4 h-4" />
  <Heroicons.chevron_down solid />
  <Heroicons.chevron_down mini />
  <Heroicons.chevron_down micro />
  <Heroicons.chevron_down outline />
  ```
  """
  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :micro, :boolean, default: false

  def chevron_down(assigns) do
    svg(
      assign(assigns,
        paths: %{
          outline:
            ~S|<path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5"/>|,
          solid:
            ~S|<path fill-rule="evenodd" d="M12.53 16.28a.75.75 0 0 1-1.06 0l-7.5-7.5a.75.75 0 0 1 1.06-1.06L12 14.69l6.97-6.97a.75.75 0 1 1 1.06 1.06l-7.5 7.5Z" clip-rule="evenodd"/>|,
          mini:
            ~S|<path fill-rule="evenodd" d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd"/>|,
          micro:
            ~S|<path fill-rule="evenodd" d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd"/>|
        }
      )
    )
  end

  @doc """
  Renders the `chevron_up` icon.

  By default, the outlined (24x24) component is used, but the `solid`, `mini` or `micro`
  attributes can be provided for alternative styles.

  You may also pass arbitrary HTML attributes to be applied to the svg tag.

  ## Examples

  ```heex
  <Heroicons.chevron_up />
  <Heroicons.chevron_up class="w-4 h-4" />
  <Heroicons.chevron_up solid />
  <Heroicons.chevron_up mini />
  <Heroicons.chevron_up micro />
  <Heroicons.chevron_up outline />
  ```
  """
  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :micro, :boolean, default: false

  def chevron_up(assigns) do
    svg(
      assign(assigns,
        paths: %{
          outline:
            ~S|<path stroke-linecap="round" stroke-linejoin="round" d="m4.5 15.75 7.5-7.5 7.5 7.5"/>|,
          solid:
            ~S|<path fill-rule="evenodd" d="M11.47 7.72a.75.75 0 0 1 1.06 0l7.5 7.5a.75.75 0 1 1-1.06 1.06L12 9.31l-6.97 6.97a.75.75 0 0 1-1.06-1.06l7.5-7.5Z" clip-rule="evenodd"/>|,
          mini:
            ~S|<path fill-rule="evenodd" d="M9.47 6.47a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 1 1-1.06 1.06L10 8.06l-3.72 3.72a.75.75 0 0 1-1.06-1.06l4.25-4.25Z" clip-rule="evenodd"/>|,
          micro:
            ~S|<path fill-rule="evenodd" d="M11.78 9.78a.75.75 0 0 1-1.06 0L8 7.06 5.28 9.78a.75.75 0 0 1-1.06-1.06l3.25-3.25a.75.75 0 0 1 1.06 0l3.25 3.25a.75.75 0 0 1 0 1.06Z" clip-rule="evenodd"/>|
        }
      )
    )
  end

  @doc """
  Renders the `chevron_left` icon.

  By default, the outlined (24x24) component is used, but the `solid`, `mini` or `micro`
  attributes can be provided for alternative styles.

  You may also pass arbitrary HTML attributes to be applied to the svg tag.

  ## Examples

  ```heex
  <Heroicons.chevron_left />
  <Heroicons.chevron_left class="w-4 h-4" />
  <Heroicons.chevron_left solid />
  <Heroicons.chevron_left mini />
  <Heroicons.chevron_left micro />
  <Heroicons.chevron_left outline />
  ```
  """
  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :micro, :boolean, default: false

  def chevron_left(assigns) do
    svg(
      assign(assigns,
        paths: %{
          outline:
            ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5"/>|,
          solid:
            ~S|<path fill-rule="evenodd" d="M7.72 12.53a.75.75 0 0 1 0-1.06l7.5-7.5a.75.75 0 1 1 1.06 1.06L9.31 12l6.97 6.97a.75.75 0 1 1-1.06 1.06l-7.5-7.5Z" clip-rule="evenodd"/>|,
          mini:
            ~S|<path fill-rule="evenodd" d="M11.78 5.22a.75.75 0 0 1 0 1.06L8.06 10l3.72 3.72a.75.75 0 1 1-1.06 1.06l-4.25-4.25a.75.75 0 0 1 0-1.06l4.25-4.25a.75.75 0 0 1 1.06 0Z" clip-rule="evenodd"/>|,
          micro:
            ~S|<path fill-rule="evenodd" d="M9.78 4.22a.75.75 0 0 1 0 1.06L7.06 8l2.72 2.72a.75.75 0 1 1-1.06 1.06L5.47 8.53a.75.75 0 0 1 0-1.06l3.25-3.25a.75.75 0 0 1 1.06 0Z" clip-rule="evenodd"/>|
        }
      )
    )
  end

  @doc """
  Renders the `chevron_right` icon.

  By default, the outlined (24x24) component is used, but the `solid`, `mini` or `micro`
  attributes can be provided for alternative styles.

  You may also pass arbitrary HTML attributes to be applied to the svg tag.

  ## Examples

  ```heex
  <Heroicons.chevron_right />
  <Heroicons.chevron_right class="w-4 h-4" />
  <Heroicons.chevron_right solid />
  <Heroicons.chevron_right mini />
  <Heroicons.chevron_right micro />
  <Heroicons.chevron_right outline />
  ```
  """
  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :micro, :boolean, default: false

  def chevron_right(assigns) do
    svg(
      assign(assigns,
        paths: %{
          outline:
            ~S|<path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5"/>|,
          solid:
            ~S|<path fill-rule="evenodd" d="M16.28 11.47a.75.75 0 0 1 0 1.06l-7.5 7.5a.75.75 0 0 1-1.06-1.06L14.69 12 7.72 5.03a.75.75 0 0 1 1.06-1.06l7.5 7.5Z" clip-rule="evenodd"/>|,
          mini:
            ~S|<path fill-rule="evenodd" d="M8.22 5.22a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.75.75 0 0 1-1.06-1.06L11.94 10 8.22 6.28a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd"/>|,
          micro:
            ~S|<path fill-rule="evenodd" d="M6.22 4.22a.75.75 0 0 1 1.06 0l3.25 3.25a.75.75 0 0 1 0 1.06l-3.25 3.25a.75.75 0 0 1-1.06-1.06L8.94 8 6.22 5.28a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd"/>|
        }
      )
    )
  end

  @doc """
  Renders the `funnel` icon.

  By default, the outlined (24x24) component is used, but the `solid`, `mini` or `micro`
  attributes can be provided for alternative styles.

  You may also pass arbitrary HTML attributes to be applied to the svg tag.

  ## Examples

  ```heex
  <Heroicons.funnel />
  <Heroicons.funnel class="w-4 h-4" />
  <Heroicons.funnel solid />
  <Heroicons.funnel mini />
  <Heroicons.funnel micro />
  <Heroicons.funnel outline />
  ```
  """
  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :micro, :boolean, default: false

  def funnel(assigns) do
    svg(
      assign(assigns,
        paths: %{
          outline:
            ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917 1.096v1.044a2.25 2.25 0 0 1-.659 1.591l-5.432 5.432a2.25 2.25 0 0 0-.659 1.591v2.927a2.25 2.25 0 0 1-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 0 0-.659-1.591L3.659 7.409A2.25 2.25 0 0 1 3 5.818V4.774c0-.54.384-1.006.917-1.096A48.32 48.32 0 0 1 12 3Z"/>|,
          solid:
            ~S|<path fill-rule="evenodd" d="M3.792 2.938A49.069 49.069 0 0 1 12 2.25c2.797 0 5.54.236 8.209.688a1.857 1.857 0 0 1 1.541 1.836v1.044a3 3 0 0 1-.879 2.121l-6.182 6.182a1.5 1.5 0 0 0-.439 1.061v2.927a3 3 0 0 1-1.658 2.684l-1.757.878A.75.75 0 0 1 9.75 21v-5.818a1.5 1.5 0 0 0-.44-1.06L3.13 7.938a3 3 0 0 1-.879-2.121V4.774c0-.897.64-1.683 1.542-1.836Z" clip-rule="evenodd"/>|,
          mini:
            ~S|<path fill-rule="evenodd" d="M2.628 1.601C5.028 1.206 7.49 1 10 1s4.973.206 7.372.601a.75.75 0 0 1 .628.74v2.288a2.25 2.25 0 0 1-.659 1.59l-4.682 4.683a2.25 2.25 0 0 0-.659 1.59v3.037c0 .684-.31 1.33-.844 1.757l-1.937 1.55A.75.75 0 0 1 8 18.25v-5.757a2.25 2.25 0 0 0-.659-1.591L2.659 6.22A2.25 2.25 0 0 1 2 4.629V2.34a.75.75 0 0 1 .628-.74Z" clip-rule="evenodd"/>|,
          micro:
            ~S|<path d="M14 2a1 1 0 0 0-1-1H3a1 1 0 0 0-1 1v2.172a2 2 0 0 0 .586 1.414l2.828 2.828A2 2 0 0 1 6 9.828v4.363a.5.5 0 0 0 .724.447l2.17-1.085A2 2 0 0 0 10 11.763V9.829a2 2 0 0 1 .586-1.414l2.828-2.828A2 2 0 0 0 14 4.172V2Z"/>|
        }
      )
    )
  end

  @doc """
  Renders the `trash` icon.

  By default, the outlined (24x24) component is used, but the `solid`, `mini` or `micro`
  attributes can be provided for alternative styles.

  You may also pass arbitrary HTML attributes to be applied to the svg tag.

  ## Examples

  ```heex
  <Heroicons.trash />
  <Heroicons.trash class="w-4 h-4" />
  <Heroicons.trash solid />
  <Heroicons.trash mini />
  <Heroicons.trash micro />
  <Heroicons.trash outline />
  ```
  """
  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :micro, :boolean, default: false

  def trash(assigns) do
    svg(
      assign(assigns,
        paths: %{
          outline:
            ~S|<path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"/>|,
          solid:
            ~S|<path fill-rule="evenodd" d="M16.5 4.478v.227a48.816 48.816 0 0 1 3.878.512.75.75 0 1 1-.256 1.478l-.209-.035-1.005 13.07a3 3 0 0 1-2.991 2.77H8.084a3 3 0 0 1-2.991-2.77L4.087 6.66l-.209.035a.75.75 0 0 1-.256-1.478A48.567 48.567 0 0 1 7.5 4.705v-.227c0-1.564 1.213-2.9 2.816-2.951a52.662 52.662 0 0 1 3.369 0c1.603.051 2.815 1.387 2.815 2.951Zm-6.136-1.452a51.196 51.196 0 0 1 3.273 0C14.39 3.05 15 3.684 15 4.478v.113a49.488 49.488 0 0 0-6 0v-.113c0-.794.609-1.428 1.364-1.452Zm-.355 5.945a.75.75 0 1 0-1.5.058l.347 9a.75.75 0 1 0 1.499-.058l-.346-9Zm5.48.058a.75.75 0 1 0-1.498-.058l-.347 9a.75.75 0 0 0 1.5.058l.345-9Z" clip-rule="evenodd"/>|,
          mini:
            ~S|<path fill-rule="evenodd" d="M8.75 1A2.75 2.75 0 0 0 6 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 1 0 .23 1.482l.149-.022.841 10.518A2.75 2.75 0 0 0 7.596 19h4.807a2.75 2.75 0 0 0 2.742-2.53l.841-10.52.149.023a.75.75 0 0 0 .23-1.482A41.03 41.03 0 0 0 14 4.193V3.75A2.75 2.75 0 0 0 11.25 1h-2.5ZM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4ZM8.58 7.72a.75.75 0 0 0-1.5.06l.3 7.5a.75.75 0 1 0 1.5-.06l-.3-7.5Zm4.34.06a.75.75 0 1 0-1.5-.06l-.3 7.5a.75.75 0 1 0 1.5.06l.3-7.5Z" clip-rule="evenodd"/>|,
          micro:
            ~S|<path fill-rule="evenodd" d="M5 3.25V4H2.75a.75.75 0 0 0 0 1.5h.3l.815 8.15A1.5 1.5 0 0 0 5.357 15h5.285a1.5 1.5 0 0 0 1.493-1.35l.815-8.15h.3a.75.75 0 0 0 0-1.5H11v-.75A2.25 2.25 0 0 0 8.75 1h-1.5A2.25 2.25 0 0 0 5 3.25Zm2.25-.75a.75.75 0 0 0-.75.75V4h3v-.75a.75.75 0 0 0-.75-.75h-1.5ZM6.05 6a.75.75 0 0 1 .787.713l.275 5.5a.75.75 0 0 1-1.498.075l-.275-5.5A.75.75 0 0 1 6.05 6Zm3.9 0a.75.75 0 0 1 .712.787l-.275 5.5a.75.75 0 0 1-1.498-.075l.275-5.5a.75.75 0 0 1 .786-.711Z" clip-rule="evenodd"/>|
        }
      )
    )
  end

  @doc """
  Renders the `list_bullet` icon.

  By default, the outlined (24x24) component is used, but the `solid`, `mini` or `micro`
  attributes can be provided for alternative styles.

  You may also pass arbitrary HTML attributes to be applied to the svg tag.

  ## Examples

  ```heex
  <Heroicons.list_bullet />
  <Heroicons.list_bullet class="w-4 h-4" />
  <Heroicons.list_bullet solid />
  <Heroicons.list_bullet mini />
  <Heroicons.list_bullet micro />
  <Heroicons.list_bullet outline />
  ```
  """
  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :micro, :boolean, default: false

  def list_bullet(assigns) do
    svg(
      assign(assigns,
        paths: %{
          outline:
            ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.007v.008H3.75V6.75Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0ZM3.75 12h.007v.008H3.75V12Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm-.375 5.25h.007v.008H3.75v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z"/>|,
          solid:
            ~S|<path fill-rule="evenodd" d="M2.625 6.75a1.125 1.125 0 1 1 2.25 0 1.125 1.125 0 0 1-2.25 0Zm4.875 0A.75.75 0 0 1 8.25 6h12a.75.75 0 0 1 0 1.5h-12a.75.75 0 0 1-.75-.75ZM2.625 12a1.125 1.125 0 1 1 2.25 0 1.125 1.125 0 0 1-2.25 0ZM7.5 12a.75.75 0 0 1 .75-.75h12a.75.75 0 0 1 0 1.5h-12A.75.75 0 0 1 7.5 12Zm-4.875 5.25a1.125 1.125 0 1 1 2.25 0 1.125 1.125 0 0 1-2.25 0Zm4.875 0a.75.75 0 0 1 .75-.75h12a.75.75 0 0 1 0 1.5h-12a.75.75 0 0 1-.75-.75Z" clip-rule="evenodd"/>|,
          mini:
            ~S|<path fill-rule="evenodd" d="M6 4.75A.75.75 0 0 1 6.75 4h10.5a.75.75 0 0 1 0 1.5H6.75A.75.75 0 0 1 6 4.75ZM6 10a.75.75 0 0 1 .75-.75h10.5a.75.75 0 0 1 0 1.5H6.75A.75.75 0 0 1 6 10Zm0 5.25a.75.75 0 0 1 .75-.75h10.5a.75.75 0 0 1 0 1.5H6.75a.75.75 0 0 1-.75-.75ZM1.99 4.75a1 1 0 0 1 1-1H3a1 1 0 0 1 1 1v.01a1 1 0 0 1-1 1h-.01a1 1 0 0 1-1-1v-.01ZM1.99 15.25a1 1 0 0 1 1-1H3a1 1 0 0 1 1 1v.01a1 1 0 0 1-1 1h-.01a1 1 0 0 1-1-1v-.01ZM1.99 10a1 1 0 0 1 1-1H3a1 1 0 0 1 1 1v.01a1 1 0 0 1-1 1h-.01a1 1 0 0 1-1-1V10Z" clip-rule="evenodd"/>|,
          micro:
            ~S|<path d="M3 4.75a1 1 0 1 0 0-2 1 1 0 0 0 0 2ZM6.25 3a.75.75 0 0 0 0 1.5h7a.75.75 0 0 0 0-1.5h-7ZM6.25 7.25a.75.75 0 0 0 0 1.5h7a.75.75 0 0 0 0-1.5h-7ZM6.25 11.5a.75.75 0 0 0 0 1.5h7a.75.75 0 0 0 0-1.5h-7ZM4 12.25a1 1 0 1 1-2 0 1 1 0 0 1 2 0ZM3 9a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z"/>|
        }
      )
    )
  end

  @doc """
  Renders the `check` icon.

  By default, the outlined (24x24) component is used, but the `solid`, `mini` or `micro`
  attributes can be provided for alternative styles.

  You may also pass arbitrary HTML attributes to be applied to the svg tag.

  ## Examples

  ```heex
  <Heroicons.check />
  <Heroicons.check class="w-4 h-4" />
  <Heroicons.check solid />
  <Heroicons.check mini />
  <Heroicons.check micro />
  <Heroicons.check outline />
  ```
  """
  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :micro, :boolean, default: false

  def check(assigns) do
    svg(
      assign(assigns,
        paths: %{
          outline:
            ~S|<path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5"/>|,
          solid:
            ~S|<path fill-rule="evenodd" d="M19.916 4.626a.75.75 0 0 1 .208 1.04l-9 13.5a.75.75 0 0 1-1.154.114l-6-6a.75.75 0 0 1 1.06-1.06l5.353 5.353 8.493-12.74a.75.75 0 0 1 1.04-.207Z" clip-rule="evenodd"/>|,
          mini:
            ~S|<path fill-rule="evenodd" d="M16.704 4.153a.75.75 0 0 1 .143 1.052l-8 10.5a.75.75 0 0 1-1.127.075l-4.5-4.5a.75.75 0 0 1 1.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 0 1 1.05-.143Z" clip-rule="evenodd"/>|,
          micro:
            ~S|<path fill-rule="evenodd" d="M12.416 3.376a.75.75 0 0 1 .208 1.04l-5 7.5a.75.75 0 0 1-1.154.114l-3-3a.75.75 0 0 1 1.06-1.06l2.353 2.353 4.493-6.74a.75.75 0 0 1 1.04-.207Z" clip-rule="evenodd"/>|
        }
      )
    )
  end

  @doc """
  Renders the `plus` icon.

  By default, the outlined (24x24) component is used, but the `solid`, `mini` or `micro`
  attributes can be provided for alternative styles.

  You may also pass arbitrary HTML attributes to be applied to the svg tag.

  ## Examples

  ```heex
  <Heroicons.plus />
  <Heroicons.plus class="w-4 h-4" />
  <Heroicons.plus solid />
  <Heroicons.plus mini />
  <Heroicons.plus micro />
  <Heroicons.plus outline />
  ```
  """
  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :micro, :boolean, default: false

  def plus(assigns) do
    svg(
      assign(assigns,
        paths: %{
          outline:
            ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15"/>|,
          solid:
            ~S|<path fill-rule="evenodd" d="M12 3.75a.75.75 0 0 1 .75.75v6.75h6.75a.75.75 0 0 1 0 1.5h-6.75v6.75a.75.75 0 0 1-1.5 0v-6.75H4.5a.75.75 0 0 1 0-1.5h6.75V4.5a.75.75 0 0 1 .75-.75Z" clip-rule="evenodd"/>|,
          mini:
            ~S|<path d="M10.75 4.75a.75.75 0 0 0-1.5 0v4.5h-4.5a.75.75 0 0 0 0 1.5h4.5v4.5a.75.75 0 0 0 1.5 0v-4.5h4.5a.75.75 0 0 0 0-1.5h-4.5v-4.5Z"/>|,
          micro:
            ~S|<path d="M8.75 3.75a.75.75 0 0 0-1.5 0v3.5h-3.5a.75.75 0 0 0 0 1.5h3.5v3.5a.75.75 0 0 0 1.5 0v-3.5h3.5a.75.75 0 0 0 0-1.5h-3.5v-3.5Z"/>|
        }
      )
    )
  end

  @doc """
  Renders the `ellipsis_vertical` icon.

  By default, the outlined (24x24) component is used, but the `solid`, `mini` or `micro`
  attributes can be provided for alternative styles.

  You may also pass arbitrary HTML attributes to be applied to the svg tag.

  ## Examples

  ```heex
  <Heroicons.ellipsis_vertical />
  <Heroicons.ellipsis_vertical class="w-4 h-4" />
  <Heroicons.ellipsis_vertical solid />
  <Heroicons.ellipsis_vertical mini />
  <Heroicons.ellipsis_vertical micro />
  <Heroicons.ellipsis_vertical outline />
  ```
  """
  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the svg container",
    include: ~w(fill stroke stroke-width)

  attr :outline, :boolean, default: true
  attr :solid, :boolean, default: false
  attr :mini, :boolean, default: false
  attr :micro, :boolean, default: false

  def ellipsis_vertical(assigns) do
    svg(
      assign(assigns,
        paths: %{
          outline:
            ~S|<path stroke-linecap="round" stroke-linejoin="round" d="M12 6.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5ZM12 12.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5ZM12 18.75a.75.75 0 1 1 0-1.5.75.75 0 0 1 0 1.5Z"/>|,
          solid:
            ~S|<path fill-rule="evenodd" d="M10.5 6a1.5 1.5 0 1 1 3 0 1.5 1.5 0 0 1-3 0Zm0 6a1.5 1.5 0 1 1 3 0 1.5 1.5 0 0 1-3 0Zm0 6a1.5 1.5 0 1 1 3 0 1.5 1.5 0 0 1-3 0Z" clip-rule="evenodd"/>|,
          mini:
            ~S|<path d="M10 3a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM10 8.5a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM11.5 15.5a1.5 1.5 0 1 0-3 0 1.5 1.5 0 0 0 3 0Z"/>|,
          micro:
            ~S|<path d="M8 2a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM8 6.5a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM9.5 12.5a1.5 1.5 0 1 0-3 0 1.5 1.5 0 0 0 3 0Z"/>|
        }
      )
    )
  end
end
