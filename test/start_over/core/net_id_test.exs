defmodule StartOver.Core.NetIDTest do
  use ExUnit.Case

  alias StartOver.Core.NetID

  describe "NetID.from_bin/1" do
    test "correctly parses a valid sponsor level NetID from a binary" do
      rfu = 3
      nwk_id = 4
      bin = <<0::3, rfu::integer()-size(15), nwk_id::integer()-size(6)>>

      expected = %NetID{
        type: :net_id_sponsor,
        rfu: rfu,
        nwk_id: nwk_id
      }

      assert(expected == NetID.from_bin(bin))
    end

    test "correctly parses a valid reserved1 level NetID from a binary" do
      rfu = 3
      nwk_id = 4
      bin = <<1::3, rfu::integer()-size(15), nwk_id::integer()-size(6)>>

      expected = %NetID{
        type: :net_id_reserved1,
        rfu: rfu,
        nwk_id: nwk_id
      }

      assert(expected == NetID.from_bin(bin))
    end

    test "correctly parses a valid reserved2 level NetID from a binary" do
      rfu = 3
      nwk_id = 4
      bin = <<2::3, rfu::integer()-size(12), nwk_id::integer()-size(9)>>

      expected = %NetID{
        type: :net_id_reserved2,
        rfu: rfu,
        nwk_id: nwk_id
      }

      assert(expected == NetID.from_bin(bin))
    end

    test "correctly parses a valid contributor level NetID from a binary" do
      nwk_id = 4
      bin = <<3::3, nwk_id::integer()-size(21)>>

      expected = %NetID{
        type: :net_id_contributor,
        rfu: nil,
        nwk_id: nwk_id
      }

      assert(expected == NetID.from_bin(bin))
    end

    test "correctly parses a valid reserved4 level NetID from a binary" do
      nwk_id = 4
      bin = <<4::3, nwk_id::integer()-size(21)>>

      expected = %NetID{
        type: :net_id_reserved4,
        rfu: nil,
        nwk_id: nwk_id
      }

      assert(expected == NetID.from_bin(bin))
    end

    test "correctly parses a valid reserved5 level NetID from a binary" do
      nwk_id = 4
      bin = <<5::3, nwk_id::integer()-size(21)>>

      expected = %NetID{
        type: :net_id_reserved5,
        rfu: nil,
        nwk_id: nwk_id
      }

      assert(expected == NetID.from_bin(bin))
    end

    test "correctly parses a valid adopter level NetID from a binary" do
      nwk_id = 4
      bin = <<6::3, nwk_id::integer()-size(21)>>

      expected = %NetID{
        type: :net_id_adopter,
        rfu: nil,
        nwk_id: nwk_id
      }

      assert(expected == NetID.from_bin(bin))
    end

    test "correctly parses a valid reserved7 level NetID from a binary" do
      nwk_id = 4
      bin = <<7::3, nwk_id::integer()-size(21)>>

      expected = %NetID{
        type: :net_id_reserved7,
        rfu: nil,
        nwk_id: nwk_id
      }

      assert(expected == NetID.from_bin(bin))
    end
  end

  describe "NetID.from_str/1" do
    test "correctly parses a sponsor level NetID from a hex string" do
      hex = Base.encode16(<<0::integer-size(3), 3::integer-size(15), 4::integer-size(6)>>)

      expected = %NetID{
        type: :net_id_sponsor,
        rfu: 3,
        nwk_id: 4
      }

      assert(expected == NetID.from_str(hex))
    end

    test "correctly parses an adopter level NetID from a hex string" do
      hex = Base.encode16(<<6::integer-size(3), 42::integer-size(21)>>)

      expected = %NetID{
        type: :net_id_adopter,
        rfu: nil,
        nwk_id: 42
      }

      assert(expected == NetID.from_str(hex))
    end
  end
end
