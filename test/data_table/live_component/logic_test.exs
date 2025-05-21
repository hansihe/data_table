defmodule DataTable.LiveComponent.LogicTest do
  use ExUnit.Case

  alias DataTable.LiveComponent.Logic
  alias DataTable.Util.DataDeps

  @simple_source {DataTable.List,
                  {Enum.map(0..9, &%{id: &1, name: "Id #{&1}"}), %DataTable.List.Config{}}}

  defp handle_nav(nav) do
    send(self(), {:handle_nav, nav})
  end

  defp get_handle_nav do
    receive do
      {:handle_nav, nav} -> {:ok, nav}
    after
      0 -> :no_message
    end
  end

  def update(assigns, changes) do
    data_deps = DataDeps.new(%Phoenix.LiveView.Socket{assigns: assigns})

    data_deps =
      if assigns == %{__changed__: %{}} do
        Logic.init(data_deps)
      else
        data_deps
      end

    socket =
      Enum.reduce(changes, data_deps, fn {key, value}, acc ->
        DataDeps.assign_input(acc, key, value)
      end)
      |> Logic.compute()
      |> DataDeps.finish()

    socket.assigns
  end

  def params(assigns \\ %{__changed__: %{}}, params) do
    update(
      assigns,
      Keyword.merge(
        [
          id: "id",
          source: @simple_source,
          theme: nil,
          col: [],
          selection_action: [],
          row_expanded: [],
          row_buttons: [],
          top_right: [],
          always_columns: [],
          handle_nav: nil,
          nav: nil
        ],
        params
      )
    )
  end

  test "basic initialization" do
    assigns = params([])

    assert assigns.total_results == 10
    assert assigns.page == 0
    assert assigns.can_expand == false
    assert assigns.can_select == false

    assert [
             %{id: 0},
             %{id: 1},
             %{id: 2},
             %{id: 3},
             %{id: 4},
             %{id: 5},
             %{id: 6},
             %{id: 7},
             %{id: 8},
             %{id: 9}
           ] = assigns.results
  end

  test "adding column works, minimal set of columns is queried" do
    assigns = params([])

    assert assigns.shown_fields == MapSet.new([])
    assert assigns.queried_columns == MapSet.new([:list_index])

    col = [
      %{
        __slot__: :col,
        name: "Id",
        fields: [:id, :name]
      }
    ]

    assigns = update(assigns, col: col)

    assert assigns.shown_fields == MapSet.new(["Id"])
    assert assigns.queried_columns == MapSet.new([:list_index, :id, :name])

    assigns =
      update(assigns, shown_fields: MapSet.new([]))

    assert assigns.shown_fields == MapSet.new([])
    assert assigns.queried_columns == MapSet.new([:list_index])
  end

  test "correctly dispatches nav" do
    # Passing in a `handle_nav` function results in update to nav state.
    assigns = params(handle_nav: &handle_nav/1)
    {:ok, nav} = get_handle_nav()
    :no_message = get_handle_nav()
    assert nav.filters == []
    assert nav.page == 0
    assert nav.sort == nil

    # Setting `nav` param to the active nav state results in no update.
    assigns = update(assigns, nav: nav)
    :no_message = get_handle_nav()

    # Setting `nav` param to a changed nav state results in update.
    updated_nav = %{nav | page: 1}
    assigns = update(assigns, nav: %{nav | page: 1})
    {:ok, nav} = get_handle_nav()
    :no_message = get_handle_nav()
    assert nav == updated_nav
  end
end
