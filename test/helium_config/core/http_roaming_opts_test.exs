defmodule HeliumConfig.Core.HttpRoamingOptsTest do
  use ExUnit.Case

  alias Proto.Helium.Config.ProtocolHttpRoamingV1
  alias HeliumConfig.Core.HttpRoamingOpts

  test "can decode from a protobuf" do
    bin =
      %{
        dedupe_timeout: 1200,
        flow_type: :async,
        path: "/helium/auth"
      }
      |> ProtocolHttpRoamingV1.new()
      |> ProtocolHttpRoamingV1.encode()

    got =
      bin
      |> ProtocolHttpRoamingV1.decode()
      |> HttpRoamingOpts.from_proto()

    expected = %HttpRoamingOpts{
      dedupe_timeout: 1200,
      flow_type: :async,
      path: "/helium/auth"
    }

    assert(got == expected)
  end

  describe "HttpRoamingOpts.from_web/1" do
    test "returns a properly formed %HttpRoamingOpts{} given properly formed JSON params" do
      protocol_opts = %{
        "type" => "http_roaming",
        "dedupe_timeout" => 1200,
        "flow_type" => "async",
        "path" => "/helium"
      }

      got = HttpRoamingOpts.from_web(protocol_opts)

      expected = %HttpRoamingOpts{
        dedupe_timeout: 1200,
        flow_type: :async,
        path: "/helium"
      }

      assert(got == expected)
    end
  end
end
