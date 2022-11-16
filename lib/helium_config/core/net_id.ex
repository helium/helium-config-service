defmodule HeliumConfig.Core.NetID do
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

  # def parse(<<_discard::binary-size(1), rest::binary-size(3)>>), do: parse(rest)

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

defimpl String.Chars, for: HeliumConfig.Core.NetID do
  def to_string(%HeliumConfig.Core.NetID{} = net_id) do
    str = HeliumConfig.Core.NetID.to_hex_str(net_id)
    "%HeliumConfig.Core.NetID{#{str}}"
  end
end
