defmodule DataTable.Source.Result do
  @type t :: %__MODULE__{}

  defstruct [
    results: [],
    total_results: nil
  ]
end
