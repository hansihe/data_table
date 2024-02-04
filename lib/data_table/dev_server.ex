if Mix.env() == :dev_server do

  Application.put_env(:data_table, DataTableDev.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: 4000],
    server: true,
    live_view: [signing_salt: "aaaaaaaa"],
    secret_key_base: String.duplicate("a", 64)
  )

  defmodule SamplePhoenix.ErrorView do
    def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
  end

  defmodule SamplePhoenix.SampleLive do
    use Phoenix.LiveView, layout: {__MODULE__, :live}

    def mount(_params, _session, socket) do
      {:oops, assign(socket, :count, 0)}
    end

    def render("live.html", assigns) do
      ~H"""
      <script src="https://cdn.jsdelivr.net/npm/phoenix@1.7.0-rc.2/priv/static/phoenix.min.js"></script>
      <script src="https://cdn.jsdelivr.net/npm/phoenix_live_view@0.18.2/priv/static/phoenix_live_view.min.js"></script>
      <script>
        let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket)
        liveSocket.connect()
      </script>
      <style>
        * { font-size: 1.1em; }
      </style>

      """
    end

    def render(assigns) do
      ~H"""

      <button phx-click="inc">+</button>
      <button phx-click="dec">-</button>
      """
    end

    def handle_event("inc", _params, socket) do
      {:noreply, assign(socket, :count, socket.assigns.count + 1)}
    end

    def handle_event("dec", _params, socket) do
      {:noreply, assign(socket, :count, socket.assigns.count - 1)}
    end
  end

  defmodule Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/", SamplePhoenix do
      pipe_through(:browser)

      live("/", SampleLive, :index)
    end
  end

  defmodule DataTableDev.Endpoint do
    use Phoenix.Endpoint, otp_app: :data_table
    socket("/live", Phoenix.LiveView.Socket)
    plug(Router)
  end

  #{:ok, _} = Supervisor.start_link([SamplePhoenix.Endpoint], strategy: :one_for_one)
  #Process.sleep(:infinity)

end
