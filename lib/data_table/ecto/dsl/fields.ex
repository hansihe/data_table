defmodule DataTable.Ecto.Dsl.Fields do

  defstruct [
    binds: nil,
    fields: []
  ]

  @opt_schema [
    binds: [
      type: :quoted,
      doc: ""
    ]
  ]

  @doc false
  def opt_schema, do: @opt_schema
end
