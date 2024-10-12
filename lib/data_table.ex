defmodule DataTable do
  @moduledoc """
  DataTable is a flexible and interactive table component for LiveView.

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
    \"""
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

  ## Common Tasks
  * [Cheat Sheet for DataTable Component](data_table_component_cheatsheet.html)
  * [Using the Ecto source](DataTable.Ecto.html)
  * [Setting up query string navigation](DataTable.NavState.html#module-persisting-datatable-state-in-query-string)

  ## Getting started
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
  ```
  "../deps/data_table/**/*.*ex"
  ```

  ## Data model

  Some terms you should know when using the library:

  * Source - A module implementing the DataTable.Source behaviour. A Source
    provides data to the DataTable component in a pluggable way.
    Examples of built-in sources are: DataTable.Ecto, DataTable.List
  * Data Row - A single row of data returned from the Source.
  * Data Field - A column of data returned from the Source. Example: In a
    database table, this might be a single field like "first_name" or "email".
  * Table Column - A column displayed in the table. A Table Field may combine or
    transform data from one or more Data Columns. Example: A "full_name" Table Field
    might combine "first_name" and "last_name" Data Columns.

  Note: Internally, Data Fields are referred to simply as "fields", while Table Columns
  are called "columns".

  To summarize, a *Source* provides *Data Fields* which are then mapped to *Table Columns*
  for display in the *DataTable* component.
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
