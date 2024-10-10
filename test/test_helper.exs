Application.put_env(
  :data_table,
  DataTable.TestEndpoint,
  [
    secret_key_base: "...............",
    live_view: [signing_salt: "............."]
  ]
)
{:ok, _pid} = DataTable.TestEndpoint.start_link([])

ExUnit.start()
