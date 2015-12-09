# gpixir

Basic genetic programming in Elixir, heavily based on https://github.com/lspector/gp

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add gp to your list of dependencies in `mix.exs`:

        def deps do
          [{:gpixir, "~> 0.0.1"}]
        end

  2. Ensure gp is started before your application:

        def application do
          [applications: [:gpixir]]
        end
