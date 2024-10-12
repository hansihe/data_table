defmodule DataTable.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_table,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),

      name: "DataTable",
      docs: docs()
    ]
  end

  def application do
    [
      mod: {DataTable.Application, []},
      extra_applications: [:logger]
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

  defp docs do
    [
      extra_section: "GUIDES",
      extras: [
        "guides/cheatsheets/data_table_component_cheatsheet.cheatmd"
      ],
      groups_for_extras: [
        Cheatsheets: ~r/cheatsheets\/.?/,
      ],
      groups_for_modules: [
        Sources: [
          DataTable.Ecto,
          DataTable.Ecto.Query,
          DataTable.List,
          DataTable.List.Config
        ],
        "Source Behaviour": [
          DataTable.Source,
          DataTable.Source.Query,
          DataTable.Source.Result
        ],
        Themes: [
          DataTable.Theme.Tailwind,
          DataTable.Theme.Basic,
          DataTable.Theme.Util
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto, "~> 3.12"},

      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},

      {:plug_cowboy, "~> 2.5", only: :dev_server},
      {:jason, "~> 1.2", only: [:dev_server, :test]},
      {:floki, ">= 0.30.0", only: :test}
    ]
  end
end
