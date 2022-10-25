defmodule StartOver.Core.PacketRouterOpts do
  defstruct []

  alias Proto.Helium.Config.ProtocolPacketRouterV1

  def new(_) do
    %__MODULE__{}
  end

  def from_proto(%{__struct__: ProtocolPacketRouterV1}), do: %__MODULE__{}

  def from_web(%{"type" => "packet_router"}) do
    %__MODULE__{}
  end

  def from_db(%{}) do
    %__MODULE__{}
  end
end
