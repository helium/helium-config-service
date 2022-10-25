defmodule StartOver.Core.HttpRoamingOptsTest do
  use ExUnit.Case

  alias Proto.Helium.Config.ProtocolHttpRoamingV1
  alias StartOver.Core.HttpRoamingOpts

  test "can decode from a protobuf" do
    bin =
      %{}
      |> ProtocolHttpRoamingV1.new()
      |> ProtocolHttpRoamingV1.encode()

    got =
      bin
      |> ProtocolHttpRoamingV1.decode()
      |> HttpRoamingOpts.from_proto()

    expected = %HttpRoamingOpts{}

    assert(got == expected)
  end

  describe "HttpRoamingOpts.from_web/1" do
    test "returns a properly formed %HttpRoamingOpts{} given properly formed JSON params" do
      protocol_opts = %{
        "type" => "http_roaming",
        "dedupe_window" => 1200,
        "auth_header" => "x-helium-auth"
      }

      got = HttpRoamingOpts.from_web(protocol_opts)

      expected = %HttpRoamingOpts{
        dedupe_window: 1200,
        auth_header: "x-helium-auth"
      }

      assert(got == expected)
    end
  end
end
