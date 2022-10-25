defmodule StartOver.Core.RouteValidatorTest do
  use ExUnit.Case

  alias StartOver.Core.RouteValidator
  alias StartOver.Core.NetID
  alias StartOver.Core.Devaddr

  describe "RouteValidator.validate_net_id/1" do
    test "returns an error when the given NetID is not an integer" do
      assert(
        {:error, "net_id must be an integer"} ==
          RouteValidator.validate_net_id("63")
      )
    end

    test "returns an error when the given NetID is larger than 24 bits" do
      assert(
        {:error, "net_id must be less than or equal to 16777215"} ==
          RouteValidator.validate_net_id(16_777_216)
      )
    end

    test "returns an error when the given NetID is 0 or less" do
      assert({:error, "net_id must be greater than 0"} == RouteValidator.validate_net_id(0))
      assert({:error, "net_id must be greater than 0"} == RouteValidator.validate_net_id(-1))
    end

    test "returns :ok when the given NetID is an integer beteween 1 and 16777215, inclusive" do
      assert(:ok == RouteValidator.validate_net_id(1))
      assert(:ok == RouteValidator.validate_net_id(16_777_215))
    end
  end

  describe "RouteValidator.validate_devaddr_range/1" do
    test "returns an error if the given devaddr range is not a tuple of integers" do
      assert(
        {:error, "devaddr range must be a tuple of 32-bit binaries ({\"10\", \"11\"})"} ==
          RouteValidator.validate_devaddr_range({"10", "11"})
      )
    end

    test "returns an error if the the given start addr is greater than the end addr" do
      start_addr = Devaddr.new(:devaddr_6x25, 21, 1)
      start_bin = Devaddr.to_integer(start_addr)

      end_addr = Devaddr.new(:devaddr_6x25, 21, 15)
      end_bin = Devaddr.to_integer(end_addr)

      # reverse start and end
      range = {end_bin, start_bin}

      assert(
        {:error, "start NwkAddr must be less than end NwkAddr in {#{end_addr}, #{start_addr}}"} ==
          RouteValidator.validate_devaddr_range(range)
      )
    end

    test "returns :ok given a valid devaddr range" do
      start_addr = Devaddr.new(:devaddr_6x25, 7, 1)
      start_bin = Devaddr.to_integer(start_addr)

      end_addr = Devaddr.new(:devaddr_6x25, 7, 255)
      end_bin = Devaddr.to_integer(end_addr)

      assert(:ok == RouteValidator.validate_devaddr_range({start_bin, end_bin}))
    end
  end

  describe "RouteValidator.validate_net_id_and_devaddr_range/2" do
    test "returns an error when the Devaddr range start has a NwkID different from the NetID" do
      nwk_id = 7
      rfu = 42
      net_id = NetID.new(:net_id_sponsor, rfu, nwk_id)
      net_id_bin = NetID.to_integer(net_id)

      devaddr_start = Devaddr.new(:devaddr_6x25, nwk_id - 1, 1)
      start_bin = Devaddr.to_integer(devaddr_start)

      devaddr_end = Devaddr.new(:devaddr_6x25, nwk_id, 15)
      end_bin = Devaddr.to_integer(devaddr_end)

      range = {start_bin, end_bin}

      assert(
        {:error,
         "start addr in {#{devaddr_start}, #{devaddr_end}} must have the same NwkID as #{net_id}"} ==
          RouteValidator.validate_net_id_and_devaddr_range(net_id_bin, range)
      )
    end

    test "returns an error when the Devaddr range end has a NwkID different from the NetID" do
      nwk_id = 7
      rfu = 42
      net_id = NetID.new(:net_id_sponsor, rfu, nwk_id)
      net_id_bin = NetID.to_integer(net_id)

      devaddr_start = Devaddr.new(:devaddr_6x25, nwk_id, 1)
      start_bin = Devaddr.to_integer(devaddr_start)

      devaddr_end = Devaddr.new(:devaddr_6x25, nwk_id - 1, 15)
      end_bin = Devaddr.to_integer(devaddr_end)

      range = {start_bin, end_bin}

      assert(
        {:error,
         "end addr in {#{devaddr_start}, #{devaddr_end}} must have the same NwkID as #{net_id}"} ==
          RouteValidator.validate_net_id_and_devaddr_range(net_id_bin, range)
      )
    end

    test "returns :ok given a valid NetID and Devaddr range" do
      nwk_id = 7
      rfu = 42
      net_id = NetID.new(:net_id_sponsor, rfu, nwk_id)
      net_id_bin = NetID.to_integer(net_id)

      devaddr_start = Devaddr.new(:devaddr_6x25, nwk_id, 1)
      devaddr_end = Devaddr.new(:devaddr_6x25, nwk_id, 255)

      start_bin = Devaddr.to_integer(devaddr_start)
      end_bin = Devaddr.to_integer(devaddr_end)

      range = {start_bin, end_bin}

      assert(:ok == RouteValidator.validate_net_id_and_devaddr_range(net_id_bin, range))
    end
  end

  describe "RouteValidator.validate_net_id_and_devaddr_ranges/2" do
    test "does not execute checks if any previous errors have been reported" do
      nwk_id = 7
      net_id = NetID.new(:net_id_sponsor, 42, nwk_id)
      net_id_bin = NetID.to_integer(net_id)

      # Range start doesn't match NwkID
      devaddr_start = Devaddr.new(:devaddr_6x25, nwk_id + 1, 1)
      start_bin = Devaddr.to_integer(devaddr_start)

      devaddr_end = Devaddr.new(:devaddr_6x25, nwk_id, 255)
      end_bin = Devaddr.to_integer(devaddr_end)

      fields = %{
        net_id: net_id_bin,
        devaddr_ranges: [{start_bin, end_bin}]
      }

      existing_errors = [{:error, "something went wrong"}]

      assert(
        existing_errors ==
          RouteValidator.validate_net_id_and_devaddr_ranges(existing_errors, fields)
      )
    end

    test "executes checks if no previous errors have been reported" do
      nwk_id = 7
      net_id = NetID.new(:net_id_sponsor, 42, nwk_id)
      net_id_bin = NetID.to_integer(net_id)

      # Range start doesn't match NwkID
      devaddr_start = Devaddr.new(:devaddr_6x25, nwk_id + 1, 1)
      start_bin = Devaddr.to_integer(devaddr_start)

      devaddr_end = Devaddr.new(:devaddr_6x25, nwk_id, 255)
      end_bin = Devaddr.to_integer(devaddr_end)

      fields = %{
        net_id: net_id_bin,
        devaddr_ranges: [{start_bin, end_bin}]
      }

      expected = [
        "start addr in {#{devaddr_start}, #{devaddr_end}} must have the same NwkID as #{net_id}"
      ]

      assert(expected == RouteValidator.validate_net_id_and_devaddr_ranges([], fields))
    end
  end
end
