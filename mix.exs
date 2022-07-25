defmodule RouterConfig.MixProject do
  use Mix.Project

  def project do
    [
      app: :router_config,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  def router_config_protos do
    [
      "src/router_config_service/v1/route.proto"
    ]
  end

  def router_config_proto_compile do
    ([
       "protoc",
       "-I",
       "./src/router_config_service",
       "--elixir_opt=package_prefix=Proto",
       "--elixir_out=../../lib/proto"
     ] ++
       router_config_protos())
    |> Enum.join(" ")
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:protobuf, "~> 0.9.0"},
      {:helium_proto,
       git: "file:///home/brandon/src/helium/proto",
       branch: "bp/router-config-service",
       compile: router_config_proto_compile(),
       app: false},
      {:ecc_compact, "1.1.1"},
      {:b58, "~> 1.0.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
