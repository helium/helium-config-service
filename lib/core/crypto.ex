defmodule RouterConfig.Core.Crypto do
  def generate_key_pair do
    {:ok, priv_key, compact_key} = :ecc_compact.generate_key()
    pub_key = :ecc_compact.recover_compact_key(compact_key)

    %{
      secret: priv_key,
      public: pub_key
    }
  end

  def mk_sig_fun(private_key = {:ECPrivateKey, _, _, _, _, _}) do
    fn bin -> :public_key.sign(bin, :sha256, private_key) end
  end

  def verify(bin, signature, pub_key) when is_binary(pub_key) do
    verify(bin, signature, b58_to_pubkey(pub_key))
  end
  
  def verify(bin, signature, pub_key = {{:ECPoint, _}, {:namedCurve, _}}) do
    :public_key.verify(bin, :sha256, signature, pub_key)
  end

  def pubkey_to_bin(pub_key = {{:ECPoint, _}, {:namedCurve, _}}) do
    case :ecc_compact.is_compact(pub_key) do
      {true, compact_key} ->
        compact_key

      false ->
        raise "not a compact key"
    end
  end

  def bin_to_pubkey(bin) do
    :ecc_compact.recover_compact_key(bin)
  end

  def bin_to_b58(bin) do
    versioned_bin = <<0::8, bin::binary>>

    <<checksum::binary-size(4), _::binary>> =
      :crypto.hash(:sha256, :crypto.hash(:sha256, versioned_bin))

    result = <<versioned_bin::binary, checksum::binary>>
    Base58.encode(result)
  end

  def b58_to_bin(b58) do
    bin = Base58.decode(b58)
    payload_size = byte_size(bin) - 5
    <<version::binary-size(1), payload::binary-size(payload_size), checksum::binary-size(4)>> = bin

    hash = :crypto.hash(:sha256, :crypto.hash(:sha256, <<version::binary, payload::binary>>))
    
    case hash do
      <<c::binary-size(4), _::binary>> when c == checksum ->
	payload
      _ ->
	raise "bad checksum"
    end
  end

  def pubkey_to_b58(pub_key = {{:ECPoint, _}, {:namedCurve, _}}) do
    pub_key
    |> pubkey_to_bin()
    |> bin_to_b58()
  end

  def b58_to_pubkey(b58) when is_binary(b58) do
    b58
    |> b58_to_bin()
    |> bin_to_pubkey()
  end
end
