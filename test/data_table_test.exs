defmodule DataTableTest do
  use ExUnit.Case
  doctest DataTable

  test "foo" do
    query = %DataTable.Source.Query{
      columns: [:id, :creator_name],
      filters: [
        {:eq, :id, 1}
      ],
      sort: {:asc, :id}
    }

    query = FoobarEctoSource.query(query)
    IO.inspect(query)
  end

  #test "greets the world" do
  #  assert DataTable.hello() == :world
  #end
end
