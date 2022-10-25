defmodule StartOver.Core.PacketRouterOptsTest do
  use ExUnit.Case

  alias Proto.Helium.Config.ProtocolPacketRouterV1
  alias StartOver.Core.PacketRouterOpts

  test "can decode from a ProtocolPacketRouterV1 protobuf" do
    bin =
      %{}
      |> ProtocolPacketRouterV1.new()
      |> ProtocolPacketRouterV1.encode()

    got =
      bin
      |> ProtocolPacketRouterV1.decode()
      |> PacketRouterOpts.from_proto()

    expected = %PacketRouterOpts{}

    assert(got == expected)
  end

  describe "PacketRouterOpts.from_web/1" do
    test "returns a properly formed PacketRouterOpts given valid json params" do
      json_params = %{
        "type" => "packet_router"
      }

      got = PacketRouterOpts.from_web(json_params)

      expected = %PacketRouterOpts{}

      assert(got == expected)
    end
  end
end
