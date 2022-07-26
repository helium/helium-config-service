defmodule HeliumConfig.MixProject do
  use Mix.Project

  def project do
    [
      app: :helium_config,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {HeliumConfig.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def router_config_protos do
    [
      "src/service/router_config.proto"
    ]
  end

  def proto_output_path() do
    Path.join(File.cwd!(), "lib/proto")
  end

  def router_config_proto_compile do
    proto_output_dir = proto_output_path()
    :ok = File.mkdir_p!(proto_output_dir)

    ([
       "protoc",
       "-I",
       "./src/service",
       "--elixir_opt=package_prefix=Proto",
       "--elixir_out=plugins=grpc:#{proto_output_dir}"
     ] ++
       router_config_protos())
    |> Enum.join(" ")
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Phoenix Dependencies
      {:phoenix, "~> 1.6.11"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},

      # Dev Tools
      {:credo, ">= 0.0.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},

      # Helium Config Service
      {:protobuf, "~> 0.9.0"},
      {:grpc, "~> 0.5.0"},
      {:helium_proto,
       git: "https://github.com/helium/proto.git",
       branch: "bp/router_config",
       compile: router_config_proto_compile(),
       app: false},
      {:libp2p_crypto, git: "https://github.com/helium/libp2p-crypto.git"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
