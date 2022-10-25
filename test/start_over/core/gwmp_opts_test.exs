defmodule StartOver.Core.GwmpOptsTest do
  use ExUnit.Case

  alias StartOver.Core.GwmpOpts

  describe "GwmpOpts.from_web/1" do
    test "returns a properly formed %GwmpOpts{} given properly formed json params" do
      json_params = %{
        "type" => "gwmp",
        "mapping" => [
          %{"region" => "US915", "port" => 1000},
          %{"region" => "EU868", "port" => 2000}
        ]
      }

      got = GwmpOpts.from_web(json_params)

      exptected = %GwmpOpts{
        mapping: [
          {:US915, 1000},
          {:EU868, 2000}
        ]
      }

      assert(got == exptected)
    end
  end
end
