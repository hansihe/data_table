defmodule DataTableTest do
  use ExUnit.Case
  doctest DataTable

  import Phoenix.LiveViewTest
  @endpoint DataTable.TestEndpoint

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  test "row expand and collapse works", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, DataTable.TestLive)

    assert not has_element?(view, "tbody > tr.expanded-row-content")

    # Expand row 3
    assert render(element(view, "tbody > tr:nth-child(3) > td.expansion > span")) == "<span>v</span>"
    render_click(element(view, "tbody > tr:nth-child(3) > td.expansion"))

    assert not has_element?(view, "tbody > tr.expanded-row-content", "Row Expanded 1")
    assert has_element?(view, "tbody > tr.expanded-row-content", "Row Expanded 2")

    # Collapse row 3
    render_click(element(view, "tbody > tr:nth-child(3) > td.expansion"))
    assert not has_element?(view, "tbody > tr.expanded-row-content")
  end

  test "pagination buttons work", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, DataTable.TestLive)

    assert render(element(view, ".pagination-desc > .start")) =~ ">0<"
    assert render(element(view, ".pagination-desc > .end")) =~ ">20<"
    assert render(element(view, ".pagination-desc > .total")) =~ ">50<"

    assert has_element?(view, "tbody > tr:first-child > td.data-cell", "Row 0")
    assert has_element?(view, "tbody > tr:last-child > td.data-cell", "Row 19")

    render_click(element(view, ".pagination-buttons > a.next"))

    assert render(element(view, ".pagination-desc > .start")) =~ ">20<"
    assert render(element(view, ".pagination-desc > .end")) =~ ">40<"
    assert render(element(view, ".pagination-desc > .total")) =~ ">50<"

    assert has_element?(view, "tbody > tr:first-child > td.data-cell", "Row 20")
    assert has_element?(view, "tbody > tr:last-child > td.data-cell", "Row 39")

    render_click(element(view, ".pagination-buttons > a.prev"))

    assert render(element(view, ".pagination-desc > .start")) =~ ">0<"
    assert render(element(view, ".pagination-desc > .end")) =~ ">20<"
    assert render(element(view, ".pagination-desc > .total")) =~ ">50<"

    assert has_element?(view, "tbody > tr:first-child > td.data-cell", "Row 0")
    assert has_element?(view, "tbody > tr:last-child > td.data-cell", "Row 19")
  end

  test "sort cycling works", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, DataTable.TestLive)

    assert has_element?(view, "th.column-header a.sort-toggle")
    assert not has_element?(view, "th.column-header span.sort_asc")
    assert not has_element?(view, "th.column-header span.sort_desc")

    render_click(element(view, "th.column-header a.sort-toggle"))
    assert has_element?(view, "th.column-header span.sort-asc")
    assert not has_element?(view, "th.column-header span.sort_desc")

    render_click(element(view, "th.column-header a.sort-toggle"))
    assert not has_element?(view, "th.column-header span.sort_asc")
    assert has_element?(view, "th.column-header span.sort-desc")

    render_click(element(view, "th.column-header a.sort-toggle"))
    assert not has_element?(view, "th.column-header span.sort_asc")
    assert not has_element?(view, "th.column-header span.sort_desc")
  end
end
