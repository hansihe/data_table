defmodule DataTable do
  @moduledoc """
  """

  use Phoenix.LiveComponent

  attr :theme, :atom,
    default: DataTable.Theme.Tailwind,
    doc: """
    The theme for the DataTable. Defaults to `DataTable.Theme.Tailwind`, a modern theme
    implemented using `tailwind`.
    """

  attr :id, :any,
    required: true,
    doc: """
    `live_data_table` is a stateful component, and requires an `id`.
    See `LiveView.LiveComponent` for more information.
    """

  attr :source, :any,
    required: true,
    doc: """
    Declares where the `DataTable` should fetch its data from.

    ```
    {source_module :: DataTable.Source.t(), source_config :: any()}
    ```

    `source_module` is a module implementing the `DataTable.Source` behaviour,
    `source_config` is the configuration passed to the `DataTable.Source` implementation.
    """

  attr :nav, :any,
    doc: """
    Override the navigation state of the table.
    Most likely only present when `handle_nav` is also present.

    `nil` will be counted as no change.
    """

  attr :handle_nav, :any,
    doc: """
    Called when the navigation state of the table has changed.
    If present, the navigation data should be passed back into the `nav` parameter.
    """

  attr :always_columns, :list,
    doc: """
    A list of column ids that will always be loaded.
    """

  slot :col, doc: "One `:col` should be sepecified for each potential column in the table" do
    attr :name, :string,
      required: true,
      doc: "Name in column header. Must be unique"

    # default: true
    attr :visible, :boolean,
      doc: "Default visibility of the column"

    # default: []
    attr :fields, :list,
      doc: "List of `field`s that will be queried when this field is visible"

    attr :filter_field, :atom,
      doc: """
      If present, cells will have a filter shortcut. The filter shortcut
      will apply a filter for the specified field.
      """
    # default: :eq
    attr :filter_field_op, :atom,
      doc: "The filter op type which will be used for the cell filter shortcut"

    attr :sort_field, :atom,
      doc: """
      If present, columns will be sortable. The sort will occur on
      the specified field. Defaults to the first field in `fields`.
      """
  end

  slot :row_expanded, doc: "Markup which will be rendered when a row is expanded" do
    # default: []
    attr :fields, :list,
      doc: "List of `field`s that will be queried when a row is expanded"
  end

  slot :top_right, doc: "Markup in the top right corner of the table"

  slot :row_buttons, doc: "Markup in the rightmost side of each row in the table" do
    attr :fields, :list,
      doc: "List of `field`s that will be queried when this field is visible"
  end

  slot :selection_action do
    attr :label, :string,
      required: true
    attr :handle_action, :any,
      required: true
  end

  @doc """
  Renders a `DataTable` in a given `LiveView` as a `LiveComponent`.

  `source` and `id` are required attributes.
  """
  @spec live_data_table(assigns :: Socket.assigns()) :: Phoenix.LiveView.Rendered.t()
  def live_data_table(assigns) do
    ~H"""
    <.live_component module={DataTable.LiveComponent} {assigns} />
    """
  end

end
