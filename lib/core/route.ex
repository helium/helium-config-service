defmodule RouterConfig.Core.Route do
  defstruct [
    :owner,
    :payer,
    :owner_signature,
    :payer_signature,
    :subnet_size,
    :oui,
    :xor_filter,
    addresses: [], # routeable host name or address
    subnets: [] # [{base_addr, size}]
  ]

  alias RouterConfig.Core.Crypto
  alias Proto.RouterConfig.V1.Route, as: PBRoute

  def new(field \\ %{})

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def encode(%__MODULE__{} = route) do
    route
    |> PBRoute.new()
    |> PBRoute.encode()
  end

  def decode(bin) when is_binary(bin) do
    bin
    |> PBRoute.decode()
    |> Map.from_struct()
    |> new()
  end

  def hash(%__MODULE__{} = route) do
    bin =
      route
      |> PBRoute.new()
      |> PBRoute.encode()

    :crypto.hash(:sha256, bin)
  end

  def sign_owner(%__MODULE__{} = route, signing_func) when is_function(signing_func) do
    signature = %__MODULE__{route | owner_signature: <<>>, payer_signature: <<>>}
    |> encode()
    |> signing_func.()

    %__MODULE__{route | owner_signature: signature}
  end

  def is_valid_owner?(%__MODULE__{owner: owner_pubkey_58, owner_signature: signature} = route) do
    encoded_route = encode(%__MODULE__{route | owner_signature: <<>>, payer_signature: <<>>})
    Crypto.verify(encoded_route, signature, owner_pubkey_58)
  end

  def sign_payer(%__MODULE__{} = route, signing_func) when is_function(signing_func) do
    signature = %__MODULE__{route | owner_signature: <<>>, payer_signature: <<>>}
    |> encode()
    |> signing_func.()

    %__MODULE__{route | payer_signature: signature}
  end

  def is_valid_payer?(%__MODULE__{payer: payer_pubkey_b58, payer_signature: signature} = route) do
    encoded_route = encode(%__MODULE__{route | payer_signature: <<>>, owner_signature: <<>>})
    Crypto.verify(encoded_route, signature, payer_pubkey_b58)
  end		      
end
