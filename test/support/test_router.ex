defmodule DataTable.TestRouter do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/", DataTable do
    pipe_through(:browser)

    live("/test", DataTable.TestLive, :index)
  end
end
