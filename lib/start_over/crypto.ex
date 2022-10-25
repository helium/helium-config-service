defmodule StartOver.Core.Crypto do
  @moduledoc """
  This module contains all of the cryptographic functions required by
  StartOver. It is intended for internal use only.

  The functions defined here are mostly wrappers around calls to
  external libraries.  Centralizing them here serves 2 main goals:

    1. The underlying implementations can be more easily replaced in
    the future.

    2. The inputs and outputs can be normalized for sanity.  (For
    example, libp2p_crypto often returns Erlang charlists.  For
    Elixir's purposes it's better to convert these to binaries.)

  """

  def generate_key_pair do
    :libp2p_crypto.generate_keys(:ecc_compact)
  end

  def mk_sig_fun(private_key) do
    :libp2p_crypto.mk_sig_fun(private_key)
  end

  def verify(bin, signature, pub_key) do
    :libp2p_crypto.verify(bin, signature, pub_key)
  end

  def pubkey_to_b58(pub_key) do
    pub_key
    |> :libp2p_crypto.pubkey_to_b58()
    |> :erlang.list_to_binary()
  end

  def b58_to_pubkey(b58) do
    b58
    |> :erlang.binary_to_list()
    |> :libp2p_crypto.b58_to_pubkey()
  end
end
