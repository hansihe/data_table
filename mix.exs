defmodule DataTable.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_table,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def package do
    [
      description: "Flexible data table component for LiveView",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/hansihe/data_table"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.19"},
      {:ecto, "~> 3.8"},
      {:petal_components, "~> 1.2"},

      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
