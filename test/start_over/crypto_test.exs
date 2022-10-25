defmodule StartOver.Core.CryptoTest do
  use ExUnit.Case

  alias StartOver.Core.Crypto

  test "generate_key_pair/0 returns a map containing a public and private key" do
    %{
      public: _,
      secret: _
    } = Crypto.generate_key_pair()
  end

  test "pubkey_to_b58/1 return the Base 58 encoding of a key" do
    %{public: pub_key} = Crypto.generate_key_pair()
    b58 = Crypto.pubkey_to_b58(pub_key)
    assert(true == is_binary(b58))
    assert(byte_size(b58) > 1)
  end

  test "b58_to_pubkey/1 decodes a Base 58 binary to a valid public key" do
    %{public: pub_key} = Crypto.generate_key_pair()
    b58 = Crypto.pubkey_to_b58(pub_key)
    got = Crypto.b58_to_pubkey(b58)
    assert(pub_key == got)
  end
end
