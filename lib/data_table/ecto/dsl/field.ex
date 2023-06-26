defmodule DataTable.Ecto.Dsl.Field do

  defstruct [
    name: nil,
    expr: nil,
    filter: nil
  ]

  @opt_schema [
    name: [
      type: :atom,
      required: true,
      doc: ""
    ],
    expr: [
      type: :quoted,
      required: true,
      doc: ""
    ],
    filter: [
      type: :atom,
    ]
  ]

  @doc false
  def opt_schema, do: @opt_schema
end
