defmodule Runtimes.MixProject do
  use Mix.Project
  # import Config

  # config :rustler_precompiled, :force_build, wasmex: true

  def project do
    [
      app: :runtimes,
      version: "0.1.1",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, ">= 0.0.0", optional: true}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      # {:credo, "~> 1.7", only: [:dev]}
    ]
  end
end
