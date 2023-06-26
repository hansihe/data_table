defmodule DataTable.Ecto.Dsl.QueryFragment do

  defstruct [
    name: nil,
    depends: [],
    query: nil,
    fields: []
  ]

  @opt_schema [
    name: [
      type: :atom,
    ],
    depends: [
      type: {:list, :atom},
    ],
    query: [
      type: {:or, [{:fun, 1}, {:fun, 2}]},
    ]
  ]

  def opt_schema, do: @opt_schema
end
