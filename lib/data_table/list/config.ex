defmodule DataTable.List.Config do
  @moduledoc """
  Configuration for the List source.
  """

  defstruct [
    key_field: :list_index,
    mapper: &__MODULE__.default_mapper/2,
  ]

  def default_mapper(item, idx) do
    Map.put(item, :list_index, idx)
  end

end
