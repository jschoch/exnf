defmodule Exnf.Mixfile do
  use Mix.Project

  def project do
    [ app: :exnf,
      version: "0.0.1",
      elixir: "~> 0.10.0",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:exlager],
    registered: [:exnf],
  mod: {Exnf, [:start_link]}]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:exlager ,">= 0.0",[github: "khia/exlager"]},
    {:jsonex,"2.0",[github: "marcelog/jsonex", tag: "2.0"]}]
  end
  defp options(env) when env in [:dev, :test] do
    IO.puts "DEBUG!!!!!!!!!!!!!!!!"
    [exlager_level: :debug, exlager_truncation_size: 8096]
  end
end
