defmodule DataTable.Ecto.Fragment do

  defstruct [
    # Names of other fragments this fragment depends on.
    # This means that if this fragment is included, the others will
    # be included as well.
    depends: [],
  ]

end
