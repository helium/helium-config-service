defmodule StartOver.Core.DevaddrTest do
  use ExUnit.Case

  alias StartOver.Core.Devaddr

  describe "Devaddr.from_bin/1" do
    test "correctly parses a valid 6x25 devaddr binary" do
      nwk_id = 7
      nwk_addr = 22

      given = <<0::1, nwk_id::6, nwk_addr::25>>

      expected = %Devaddr{
        type: :devaddr_6x25,
        nwk_id: nwk_id,
        nwk_addr: nwk_addr
      }

      assert(expected == Devaddr.from_bin(given))
    end

    test "correctly parses a valid 6x24 devaddr binary" do
      nwk_id = 7
      nwk_addr = 22

      given = <<2::2, nwk_id::6, nwk_addr::24>>

      expected = %Devaddr{
        type: :devaddr_6x24,
        nwk_id: nwk_id,
        nwk_addr: nwk_addr
      }

      assert(expected == Devaddr.from_bin(given))
    end

    test "correctly parses a valid 9x20 devaddr binary" do
      nwk_id = 7
      nwk_addr = 22

      given = <<6::3, nwk_id::9, nwk_addr::20>>

      expected = %Devaddr{
        type: :devaddr_9x20,
        nwk_id: nwk_id,
        nwk_addr: nwk_addr
      }

      assert(expected == Devaddr.from_bin(given))
    end

    test "correctly parses a valid 11x17 devaddr binary" do
      nwk_id = 7
      nwk_addr = 22

      given = <<14::4, nwk_id::11, nwk_addr::17>>

      expected = %Devaddr{
        type: :devaddr_11x17,
        nwk_id: nwk_id,
        nwk_addr: nwk_addr
      }

      assert(expected == Devaddr.from_bin(given))
    end

    test "correctly parses a valid 12x15 devaddr binary" do
      nwk_id = 7
      nwk_addr = 22

      given = <<30::5, nwk_id::12, nwk_addr::15>>

      expected = %Devaddr{
        type: :devaddr_12x15,
        nwk_id: nwk_id,
        nwk_addr: nwk_addr
      }

      assert(expected == Devaddr.from_bin(given))
    end

    test "correctly parses a valid 13x13 devaddr binary" do
      nwk_id = 7
      nwk_addr = 22

      given = <<62::6, nwk_id::13, nwk_addr::13>>

      expected = %Devaddr{
        type: :devaddr_13x13,
        nwk_id: nwk_id,
        nwk_addr: nwk_addr
      }

      assert(expected == Devaddr.from_bin(given))
    end

    test "correctly parses a valid 15x10 devaddr binary" do
      nwk_id = 7
      nwk_addr = 22

      given = <<126::7, nwk_id::15, nwk_addr::10>>

      expected = %Devaddr{
        type: :devaddr_15x10,
        nwk_id: nwk_id,
        nwk_addr: nwk_addr
      }

      assert(expected == Devaddr.from_bin(given))
    end

    test "correctly parses a valid 17x7 devaddr binary" do
      nwk_id = 7
      nwk_addr = 22

      given = <<254::8, nwk_id::17, nwk_addr::7>>

      expected = %Devaddr{
        type: :devaddr_17x7,
        nwk_id: nwk_id,
        nwk_addr: nwk_addr
      }

      assert(expected == Devaddr.from_bin(given))
    end
  end
end
