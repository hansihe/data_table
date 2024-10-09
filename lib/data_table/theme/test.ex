defmodule DataTable.Theme.Test do
  @moduledoc """
  Bare minimum DataTable theme designed with two purposes in mind:
  * Serve as a bare minimum example for people wanting to develop their own
  * Simple theme for use in tests

  Do not expect anything pretty if you try it yourself.
  """
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <div>
    </div>
    """
  end

end
