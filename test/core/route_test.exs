defmodule HeliumConfig.Core.RouteTest do
  use ExUnit.Case

  alias HeliumConfig.Core.Route

  test "has the expected fields" do
    expected =
      MapSet.new([
        :net_id,
        :lns,
        :euis,
        :devaddr_ranges
      ])

    got_struct = Route.new()

    got =
      got_struct
      |> Map.from_struct()
      |> Map.keys()
      |> MapSet.new()

    assert(got == expected)

    assert(is_list(got_struct.devaddr_ranges))
    assert(is_list(got_struct.euis))
  end
end
