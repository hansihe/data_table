defmodule DataTable.Assigns do

  @typedoc """

  """
  @type t :: %{
    can_select: boolean(),
    has_selection: boolean(),
    header_selection: true | false | :dash,
    selection: selection()
  }

  @type selection :: {:include, map()} | {:exclude, map()}

end
