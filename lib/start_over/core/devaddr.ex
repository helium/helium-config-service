defmodule StartOver.Core.NetID do
  defstruct [:type, :rfu, :nwk_id]

  def new(type, rfu, nwk_id) do
    struct!(
      __MODULE__,
      %{
        type: type,
        rfu: rfu,
        nwk_id: nwk_id
      }
    )
  end

  def type_to_bits(:net_id_sponsor), do: {<<0::3>>, 15, 6}
  def type_to_bits(:net_id_reserved1), do: {<<1::3>>, 15, 6}
  def type_to_bits(:net_id_reserved2), do: {<<2::3>>, 12, 9}
  def type_to_bits(:net_id_contributor), do: {<<3::3>>, 0, 21}
  def type_to_bits(:net_id_reserved4), do: {<<4::3>>, 0, 21}
  def type_to_bits(:net_id_reserved5), do: {<<5::3>>, 0, 21}
  def type_to_bits(:net_id_adopter), do: {<<6::3>>, 0, 21}
  def type_to_bits(:net_id_reserved7), do: {<<7::3>>, 0, 21}

  def to_binary(%__MODULE__{} = net_id) do
    {type, rfu_size, nwk_id_size} = type_to_bits(net_id.type)

    <<type::bits, net_id.rfu::integer()-size(rfu_size),
      net_id.nwk_id::integer()-size(nwk_id_size)>>
  end

  def to_integer(%__MODULE__{} = net_id) do
    <<int::integer-unsigned-size(24)>> =
      net_id
      |> to_binary()

    int
  end

  def from_integer(int) when is_integer(int) do
    from_bin(<<int::integer-unsigned-size(24)>>)
  end

  def from_str(str) do
    str
    |> Base.decode16!()
    |> from_bin()
  end

  def from_bin(bin) do
    {type, rfu, nwk_id} = parse(bin)

    %__MODULE__{
      type: type,
      rfu: rfu,
      nwk_id: nwk_id
    }
  end

  def to_hex_str(%__MODULE__{} = net_id) do
    net_id
    |> to_binary()
    |> Base.encode16()
  end

  def parse(<<0::3, rfu::integer()-size(15), nwk_id::integer-size(6)>>),
    do: {:net_id_sponsor, rfu, nwk_id}

  def parse(<<1::3, rfu::integer()-size(15), nwk_id::integer-size(6)>>),
    do: {:net_id_reserved1, rfu, nwk_id}

  def parse(<<2::3, rfu::integer()-size(12), nwk_id::integer-size(9)>>),
    do: {:net_id_reserved2, rfu, nwk_id}

  def parse(<<3::3, nwk_id::integer()-size(21)>>), do: {:net_id_contributor, nil, nwk_id}
  def parse(<<4::3, nwk_id::integer()-size(21)>>), do: {:net_id_reserved4, nil, nwk_id}
  def parse(<<5::3, nwk_id::integer()-size(21)>>), do: {:net_id_reserved5, nil, nwk_id}
  def parse(<<6::3, nwk_id::integer()-size(21)>>), do: {:net_id_adopter, nil, nwk_id}
  def parse(<<7::3, nwk_id::integer()-size(21)>>), do: {:net_id_reserved7, nil, nwk_id}
end

defimpl String.Chars, for: StartOver.Core.NetID do
  def to_string(%StartOver.Core.NetID{} = net_id) do
    str = StartOver.Core.NetID.to_hex_str(net_id)
    "%StartOver.Core.NetID{#{str}}"
  end
end

defmodule StartOver.Core.Devaddr do
  defstruct [:type, :nwk_id, :nwk_addr]

  def new(type, nwk_id, nwk_addr) do
    struct!(
      __MODULE__,
      %{
        type: type,
        nwk_id: nwk_id,
        nwk_addr: nwk_addr
      }
    )
  end

  def type_to_bits(:devaddr_6x25), do: {<<0::1>>, 6, 25}
  def type_to_bits(:devaddr_6x24), do: {<<2::2>>, 6, 24}
  def type_to_bits(:devaddr_9x20), do: {<<6::3>>, 9, 20}
  def type_to_bits(:devaddr_11x17), do: {<<14::4>>, 11, 17}
  def type_to_bits(:devaddr_12x15), do: {<<30::5>>, 12, 15}
  def type_to_bits(:devaddr_13x13), do: {<<62::6>>, 13, 13}
  def type_to_bits(:devaddr_15x10), do: {<<127::7>>, 15, 10}
  def type_to_bits(:devaddr_17x7), do: {<<254::8>>, 17, 7}

  def to_binary(%__MODULE__{} = devaddr) do
    {type, nwk_size, addr_size} = type_to_bits(devaddr.type)

    <<type::bits, devaddr.nwk_id::integer()-size(nwk_size),
      devaddr.nwk_addr::integer()-size(addr_size)>>
  end

  def from_str(str) do
    str
    |> Base.decode16!()
    |> from_bin()
  end

  def to_hex_str(%__MODULE__{} = devaddr) do
    devaddr
    |> to_binary()
    |> Base.encode16()
  end

  def from_bin(bin) do
    {type, nwk_id, nwk_addr} =
      bin
      |> parse_type()
      |> parse_nwk_id_and_addr()

    %__MODULE__{
      type: type,
      nwk_id: nwk_id,
      nwk_addr: nwk_addr
    }
  end

  def from_integer(int) do
    <<int::integer-unsigned-size(32)>>
    |> from_bin()
  end

  def to_integer(%__MODULE__{} = devaddr) do
    <<int::integer-unsigned-size(32)>> =
      devaddr
      |> to_binary()

    int
  end

  def parse_type(<<0::1, rest::bits-size(31)>>), do: {:devaddr_6x25, 6, 25, rest}
  def parse_type(<<2::2, rest::bits-size(30)>>), do: {:devaddr_6x24, 6, 24, rest}
  def parse_type(<<6::3, rest::bits-size(29)>>), do: {:devaddr_9x20, 9, 20, rest}
  def parse_type(<<14::4, rest::bits-size(28)>>), do: {:devaddr_11x17, 11, 17, rest}
  def parse_type(<<30::5, rest::bits-size(27)>>), do: {:devaddr_12x15, 12, 15, rest}
  def parse_type(<<62::6, rest::bits-size(26)>>), do: {:devaddr_13x13, 13, 13, rest}
  def parse_type(<<126::7, rest::bits-size(25)>>), do: {:devaddr_15x10, 15, 10, rest}
  def parse_type(<<254::8, rest::bits-size(24)>>), do: {:devaddr_17x7, 17, 7, rest}
  def parse_type(_), do: raise(ArgumentError, message: "error parsing Devaddr type")

  def parse_nwk_id_and_addr({type, nwk_id_size, nwk_addr_size, rest}) do
    case rest do
      <<nwk_id::integer()-size(nwk_id_size), nwk_addr::integer()-size(nwk_addr_size)>> ->
        {type, nwk_id, nwk_addr}

      _ ->
        raise ArgumentError, message: "error parsing NwkID and NwkAddr"
    end
  end
end

defimpl String.Chars, for: StartOver.Core.Devaddr do
  def to_string(%StartOver.Core.Devaddr{} = devaddr) do
    str =
      devaddr
      |> StartOver.Core.Devaddr.to_binary()
      |> Base.encode16()

    "%StartOver.Core.Devaddr{#{str}}"
  end
end
