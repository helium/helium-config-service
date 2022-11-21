defmodule HeliumConfig.Core.DevaddrRangeTest do
  use ExUnit.Case

  alias HeliumConfig.Core.Devaddr
  alias HeliumConfig.Core.DevaddrRange

  describe "DevaddrRange.member?" do
    test "returns true given a valid devaddr range an a devaddr in that range" do
      nwk_id = 42
      start_addr = Devaddr.new(:devaddr_11x17, nwk_id, 5)
      end_addr = Devaddr.new(:devaddr_11x17, nwk_id, 7)
      range = {start_addr, end_addr}

      test_addr = Devaddr.new(:devaddr_11x17, nwk_id, 6)

      assert(true == DevaddrRange.member?(range, test_addr))
    end

    test "includes the first and last addresses in the range" do
      nwk_id = 42
      start_addr = Devaddr.new(:devaddr_11x17, nwk_id, 5)
      end_addr = Devaddr.new(:devaddr_11x17, nwk_id, 7)
      range = {start_addr, end_addr}

      test_addr1 = Devaddr.new(:devaddr_11x17, nwk_id, 5)
      test_addr2 = Devaddr.new(:devaddr_11x17, nwk_id, 7)

      assert(true == DevaddrRange.member?(range, test_addr1))
      assert(true == DevaddrRange.member?(range, test_addr2))
    end

    test "returns false given a valid devaddr range and a devaddr outside that range" do
      nwk_id = 42
      start_addr = Devaddr.new(:devaddr_11x17, nwk_id, 5)
      end_addr = Devaddr.new(:devaddr_11x17, nwk_id, 7)
      range = {start_addr, end_addr}

      test_addr = Devaddr.new(:devaddr_11x17, nwk_id, 8)

      assert(false == DevaddrRange.member?(range, test_addr))
    end

    test "returns false given an invalid devaddr range where the start addr is less than the end addr" do
      nwk_id = 42
      start_addr = Devaddr.new(:devaddr_11x17, nwk_id, 7)
      end_addr = Devaddr.new(:devaddr_11x17, nwk_id, 5)
      range = {start_addr, end_addr}

      test_addr = Devaddr.new(:devaddr_11x17, nwk_id, 6)

      assert(false == DevaddrRange.member?(range, test_addr))
    end

    test "returns false given an invalid devaddr range composed of mismatched devaddr types" do
      nwk_id = 42
      start_addr = Devaddr.new(:devaddr_11x17, nwk_id, 5)
      end_addr = Devaddr.new(:devaddr_6x25, nwk_id, 7)
      range = {start_addr, end_addr}

      test_addr = Devaddr.new(:devaddr_11x17, nwk_id, 6)

      assert(false == DevaddrRange.member?(range, test_addr))
    end
  end
end
