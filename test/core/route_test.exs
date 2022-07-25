defmodule RouterConfig.Core.RouteTest do
  use ExUnit.Case

  alias RouterConfig.Core.Crypto
  alias RouterConfig.Core.Route
  alias Proto.RouterConfig.V1.Route, as: RoutePB

  test "has the expected fields" do
    expected =
      MapSet.new([
        :addresses,
        :oui,
        :owner,
        :owner_signature,
        :payer,
        :payer_signature,
        :subnet_size,
	:subnets,
	:xor_filter,
        :__struct__
      ])

    # 

    got =
      Route.new()
      |> Map.keys()
      |> MapSet.new()

    assert(got == expected)
  end

  test "encode/1 encodes a Route as a protocol buffer" do
    params = %{
      owner: "BuyerPubKey",
      payer: "PayerSubKey",
      subnet_size: 10,
      oui: 12345,
      owner_signature: <<>>,
      payer_signature: <<>>
    }

    expected =
      params
      |> RoutePB.new()
      |> RoutePB.encode()

    assert(is_binary(expected))

    got =
      params
      |> Route.new()
      |> Route.encode()

    assert(is_binary(got))

    assert(got == expected)
  end

  test "decode/1 decodes a binary into a RouterConfig.Core.Route" do
    params = %{
      owner: "BuyerPubKey",
      payer: "PayerPubKey",
      subnet_size: 10,
      oui: 12345,
      owner_signature: <<>>,
      payer_signature: <<>>
    }

    expected = %Route{
      owner: "BuyerPubKey",
      payer: "PayerPubKey",
      subnet_size: 10,
      oui: 12345,
      owner_signature: <<>>,
      payer_signature: <<>>
    }

    bin =
      params
      |> Route.new()
      |> Route.encode()

    got = Route.decode(bin)

    assert(got == expected)
  end

  test "hash/1 returns a binary sha256 hash" do
    params = %{
      owner: "BuyerPubKey",
      payer: "PayerPubKey",
      subnet_size: 10,
      oui: 12345,
      owner_signature: <<>>,
      payer_signature: <<>>
    }

    route = Route.new(params)

    hash = Route.hash(route)

    bin = Route.encode(route)
    expected = :crypto.hash(:sha256, bin)

    assert(hash == expected)
  end

  test "sign_owner/2 populates the owner_signature field with a valid signature" do
    %{public: pub_key, secret: priv_key} = Crypto.generate_key_pair()
    signing_func = Crypto.mk_sig_fun(priv_key)
    params = %{
      owner: Crypto.pubkey_to_b58(pub_key),
      payer: "PayerPubKeyB58",
      subnet_size: 32,
      oui: 4567,
      owner_signature: <<>>,
      payer_signature: <<>>
    }
    route = Route.new(params)
    encoded_route = Route.encode(route)
    
    %Route{owner_signature: got_signature} = Route.sign_owner(route, signing_func)

    assert(byte_size(got_signature) > 0)
    assert(:public_key.verify(encoded_route, :sha256, got_signature, pub_key))
  end

  describe "is_valid_owner/1" do
    test "returns true if owner_signature contains a valid signature" do
      %{public: owner_pubkey, secret: owner_priv_key} = Crypto.generate_key_pair()
      owner_sig_func = Crypto.mk_sig_fun(owner_priv_key)

      params = %{
	owner: Crypto.pubkey_to_b58(owner_pubkey),
	payer: "PayerPubKeyB58",
	subnet_size: 11,
	oui: 5432,
	owner_signature: <<>>,
	payer_signature: <<>>
      }

      route = Route.new(params)
      signed_route = Route.sign_owner(route, owner_sig_func)
      assert(true == Route.is_valid_owner?(signed_route))
    end

    test "returns false if owner_signature contains an invalid signature" do
      %{public: owner_pubkey, secret: owner_priv_key} = Crypto.generate_key_pair()
      owner_sig_func = Crypto.mk_sig_fun(owner_priv_key)
      
      params = %{
	owner: Crypto.pubkey_to_b58(owner_pubkey),
	payer: "PayerPubKeyB58",
	subnet_size: 11,
	oui: 5432,
	owner_signature: <<>>,
	payer_signature: <<>>
      }
      
      route = Route.new(params)
      signed_route = Route.sign_owner(route, owner_sig_func)

      # The signature should be valid now.
      assert(true == Route.is_valid_owner?(signed_route))

      # If we change any of these fields, the signature should be invalid.
      broken_signed_route1 = %Route{signed_route | payer: "ChangedPayer"}
      assert(false == Route.is_valid_owner?(broken_signed_route1))
      
      broken_signed_route2 = %Route{signed_route | subnet_size: 12}
      assert(false == Route.is_valid_owner?(broken_signed_route2))
      
      broken_signed_route3 = %Route{signed_route | oui: 5678}
      assert(false == Route.is_valid_owner?(broken_signed_route3))

      # Changing the payer signature should not invalidate the owner signature.
      signed_route4 = %Route{signed_route | payer_signature: "ChangedPayerSig"}
      assert(true == Route.is_valid_owner?(signed_route4))
    end
  end

  describe "is_valid_payer/1" do
    test "returns true if payer_signature contains a valid signature" do
      %{public: payer_pubkey, secret: payer_priv_key} = Crypto.generate_key_pair()
      payer_sig_func = Crypto.mk_sig_fun(payer_priv_key)

      params = %{
	owner: "OnwerPubKeyB58",
	payer: Crypto.pubkey_to_b58(payer_pubkey),
	subnet_size: 11,
	oui: 5432,
	owner_signature: <<>>,
	payer_signature: <<>>
      }

      route = Route.new(params)
      signed_route = Route.sign_payer(route, payer_sig_func)
      assert(true == Route.is_valid_payer?(signed_route))
    end

    test "returns false if payer_signature contains an invalid signature" do
      %{public: payer_pubkey, secret: payer_priv_key} = Crypto.generate_key_pair()
      payer_sig_func = Crypto.mk_sig_fun(payer_priv_key)
      
      params = %{
	owner: "OwnerPubKeyB58",
	payer: Crypto.pubkey_to_b58(payer_pubkey),
	subnet_size: 11,
	oui: 5432,
	owner_signature: <<>>,
	payer_signature: <<>>
      }
      
      route = Route.new(params)
      signed_route = Route.sign_payer(route, payer_sig_func)

      # The signature should be valid now.
      assert(true == Route.is_valid_payer?(signed_route))

      # If we change any of these fields, the signature should be invalid.
      broken_signed_route1 = %Route{signed_route | owner: "ChangedOwner"}
      assert(false == Route.is_valid_payer?(broken_signed_route1))
      
      broken_signed_route2 = %Route{signed_route | subnet_size: 12}
      assert(false == Route.is_valid_payer?(broken_signed_route2))
      
      broken_signed_route3 = %Route{signed_route | oui: 5678}
      assert(false == Route.is_valid_payer?(broken_signed_route3))

      # Changing the owner signature should not invalidate the payer signature.
      signed_route4 = %Route{signed_route | owner_signature: "ChangedOwnerSig"}
      assert(true == Route.is_valid_payer?(signed_route4))
    end
  end
end
