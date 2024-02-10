defmodule DataTable.Application do
  use Application

  if Mix.env() == :dev_server do
    @dev_server_children [
      DataTableDev.Endpoint
    ]
  else
    @dev_server_children []
  end

  def start(_type, _args) do
    children = [] ++ @dev_server_children
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
