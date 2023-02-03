defmodule EqLabs.Mixfile do
  use Mix.Project

  def project do
    [
      app: :eq_labs_cache,
      version: "0.1.0",
      elixir: "~> 1.11",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      config_path: "./config/config.exs",
      dialyzer: [
        plt_add_deps: :apps_direct,
        plt_add_apps: [],
        plt_ignore_apps: [
          # :httpoison,
          # :jason,
          # :tesla
        ],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: [
          "-Wunmatched_returns",
          :error_handling,
          # :race_conditions,
          :underspecs
        ],
        paths: [
          "_build/dev/lib/eq_labs_cache/ebin"
        ],
        # ignore_warnings: "dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {EqLabs.Application, [
        EqLabs.Cache
      ]}
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.2",  only: [:dev], runtime: false},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.4"},
      {:tesla, "~> 1.4"}
    ]
  end
end
