defmodule DataTable.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :data_table

  socket("/live", Phoenix.LiveView.Socket)
  plug(DataTable.TestRouter)
end
