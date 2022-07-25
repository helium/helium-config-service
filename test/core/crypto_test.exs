defmodule RouterConfig.Core.CryptoTest do
  use ExUnit.Case

  alias RouterConfig.Core.Crypto

  test "generate_key_pair/0 returns a map containing a public and private key" do
    %{
      public: {{:ECPoint, _}, {:namedCurve, _}},
      secret: {:ECPrivateKey, _, _, {:namedCurve, _}, _, _}
    } = Crypto.generate_key_pair()
  end

  test "mk_sig_fun/1 returns a signing function" do
    %{public: pub_key, secret: priv_key} = Crypto.generate_key_pair()
    f = Crypto.mk_sig_fun(priv_key)
    assert(is_function(f))

    sig = f.("Hello World")
    assert(true == :public_key.verify("Hello World", :sha256, sig, pub_key))
    assert(false == :public_key.verify("Not the same message", :sha256, sig, pub_key))
  end

  test "verify/3 returns true given valid arguments" do
    %{public: pub_key, secret: priv_key} = Crypto.generate_key_pair()
    msg = "Hello World"
    sig_fun = Crypto.mk_sig_fun(priv_key)
    sig = sig_fun.(msg)
    assert(true == Crypto.verify(msg, sig, pub_key))
  end

  test "pubkey_to_bin/1 returns a correct compact key as a binary given a valid pubkey" do
    %{public: pub_key} = Crypto.generate_key_pair()
    compact = Crypto.pubkey_to_bin(pub_key)
    assert(is_binary(compact))
  end

  test "bin_to_pubkey/1 returns a correct public key given a valid compact binary key" do
    %{public: pub_key} = Crypto.generate_key_pair()
    compact = Crypto.pubkey_to_bin(pub_key)
    pub_key_2 = Crypto.bin_to_pubkey(compact)
    assert(pub_key_2 == pub_key)
  end

  test "bin_to_b58/1 returns a binary containing a correct encoding of the given argument" do
    payload = "Hello World"
    versioned_payload = <<0::8, payload::binary>>

    <<checksum::binary-size(4), _::binary>> =
      :crypto.hash(:sha256, :crypto.hash(:sha256, versioned_payload))

    result = <<versioned_payload::binary, checksum::binary>>
    expected = Base58.encode(result)

    got = Crypto.bin_to_b58("Hello World")
    assert(got == expected)
  end

  test "b58_to_bin/1 returns the correct original binary given a valid b58 argument" do
    payload = "Hello World"
    b58_payload = Crypto.bin_to_b58(payload)
    assert(payload == Crypto.b58_to_bin(b58_payload))
  end
end
