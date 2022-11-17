defmodule HeliumConfig.Core.DevaddrRange do
  alias HeliumConfig.Core.Devaddr
  alias HeliumConfig.Core.NetID

  def new(%{type: type, nwk_id: nwk_id, start_nwk_addr: s, end_nwk_addr: e}) do
    new(type, nwk_id, s, e)
  end

  def new(type, nwk_id, start_addr, end_addr) do
    s = Devaddr.new(type, nwk_id, start_addr)
    e = Devaddr.new(type, nwk_id, end_addr)
    {s, e}
  end

  def from_web(%{"start_addr" => start_addr, "end_addr" => end_addr})
      when is_integer(start_addr) and is_integer(end_addr) do
    s = Devaddr.from_integer(start_addr)
    e = Devaddr.from_integer(end_addr)
    {s, e}
  end

  def from_web(%{"start_addr" => start_addr, "end_addr" => end_addr})
      when is_binary(start_addr) and is_binary(end_addr) do
    s = Devaddr.from_str(start_addr)
    e = Devaddr.from_str(end_addr)
    {s, e}
  end

  def from_net_id(%NetID{type: net_id_type, nwk_id: nwk_id}) do
    devaddr_type = net_id_type_to_devaddr_type(net_id_type)
    {_, _, addr_size} = Devaddr.type_to_bits(devaddr_type)

    start_addr = Devaddr.new(devaddr_type, nwk_id, 0)
    last_addr = trunc(:math.pow(2, addr_size) - 1)
    end_addr = Devaddr.new(devaddr_type, nwk_id, last_addr)

    {start_addr, end_addr}
  end

  def to_net_id({%Devaddr{} = s, %Devaddr{}}) do
    net_id_type = devaddr_type_to_net_id_type(s.type)
    nwk_id = s.nwk_id

    NetID.new(net_id_type, nwk_id)
  end

  def devaddr_type_to_net_id_type(:devaddr_6x25), do: :net_id_sponsor
  def devaddr_type_to_net_id_type(:devaddr_6x24), do: :net_id_reserved1
  def devaddr_type_to_net_id_type(:devaddr_9x20), do: :net_id_reserved2
  def devaddr_type_to_net_id_type(:devaddr_11x17), do: :net_id_contributor
  def devaddr_type_to_net_id_type(:devaddr_12x15), do: :net_id_reserved4
  def devaddr_type_to_net_id_type(:devaddr_13x13), do: :net_id_reserved5
  def devaddr_type_to_net_id_type(:devaddr_15x10), do: :net_id_adopter
  def devaddr_type_to_net_id_type(:devaddr_17x7), do: :net_id_reserved7

  def member?(
        {
          %Devaddr{type: addr_type, nwk_id: nwk_id, nwk_addr: start_addr},
          %Devaddr{type: addr_type, nwk_id: nwk_id, nwk_addr: end_addr}
        },
        %Devaddr{type: addr_type, nwk_id: nwk_id, nwk_addr: addr}
      ) do
    addr >= start_addr and addr <= end_addr
  end

  def member?(_, _), do: false

  def net_id_type_to_devaddr_type(:net_id_sponsor), do: :devaddr_6x25
  def net_id_type_to_devaddr_type(:net_id_reserved1), do: :devaddr_6x24
  def net_id_type_to_devaddr_type(:net_id_reserved2), do: :devaddr_9x20
  def net_id_type_to_devaddr_type(:net_id_contributor), do: :devaddr_11x17
  def net_id_type_to_devaddr_type(:net_id_reserved4), do: :devaddr_12x15
  def net_id_type_to_devaddr_type(:net_id_reserved5), do: :devaddr_13x13
  def net_id_type_to_devaddr_type(:net_id_adopter), do: :devaddr_15x10
  def net_id_type_to_devaddr_type(:net_id_reserved7), do: :devaddr_17x7
end
