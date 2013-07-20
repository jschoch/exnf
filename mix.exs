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
    [applications: [:lager],
    registered: [:exnf],
  mod: {Exnf, [:start_link]}]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [{:exlager ,%r".*",[github: "khia/exlager"]}]
  end
end
