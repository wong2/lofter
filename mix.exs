defmodule Lofter.Mixfile do
  use Mix.Project

  def project do
    [app: :lofter,
     version: "0.0.1",
     elixir: "~> 1.2",
     escript: escript,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp escript do
    [main_module: Lofter]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8.0"},
      {:floki, "~> 0.7"},
      {:parallel, github: "eproxus/parallel", ref: "08337182573befc55f4aea835b0f68c686d57002"},
      {:poison, github: "devinus/poison", tag: "2.1.0"},
    ]
  end
end
