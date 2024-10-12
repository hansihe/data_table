defmodule DataTable.Source.Query do
  @type t :: %__MODULE__{}

  # @types [
  #   number: [:eq, :ne, :lt, :lte, :gt, :gte, :in],
  #   boolean: [:eq, :ne, :not, :and, :or, :xor],
  #   string: [:eq, :ne, :lt, :lte, :gt, :gte, :contains, :in, :regex],
  # ]

  # @operators [
  #   eq: [:expr, :expr],
  #   ne: [:expr, :expr],

  #   lt: [:expr, :expr],
  #   lte: [:value, :value],

  #   gt: [:value, :value],
  #   gte: [:value, :value],

  #   contains: [:value, :value],
  #   in: [],
  #   regex: [],

  #   not: [],
  #   and: [],
  #   or: [],
  #   xor: [],
  # ]

  defstruct [
    fields: [],
    filters: [],
    sort: nil,
    offset: 0,
    limit: 10
  ]
end
