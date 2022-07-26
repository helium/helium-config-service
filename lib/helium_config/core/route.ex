defmodule HeliumConfig.Core.Route do
  @moduledoc """
  Data module representing a Route.
  """

  defstruct net_id: nil,
            lns_address: nil,
            protocol: nil,
            euis: [],
            devaddr_ranges: []

  alias HeliumConfig.DB

  def new(fields \\ %{}) do
    struct!(__MODULE__, fields)
  end

  def from_web(web_fields = %{}) do
    params =
      web_fields
      |> Enum.reduce(%{}, fn
        {"net_id", net_id}, acc ->
          Map.put(acc, :net_id, net_id)

        {"lns_address", lns_address}, acc ->
          Map.put(acc, :lns_address, lns_address)

        {"protocol", protocol}, acc ->
          Map.put(acc, :protocol, protocol_from_web(protocol))

        {"euis", euis}, acc ->
          Map.put(acc, :euis, Enum.map(euis, &eui_from_web/1))

        {"devaddr_ranges", ranges}, acc ->
          Map.put(acc, :devaddr_ranges, Enum.map(ranges, &devaddr_range_from_web/1))
      end)

    struct!(__MODULE__, params)
  end

  defp protocol_from_web("http"), do: :http
  defp protocol_from_web("gwmp"), do: :gwmp

  defp eui_from_web(%{"dev_eui" => dev, "app_eui" => app}) do
    %{
      dev_eui: dev,
      app_eui: app
    }
  end

  defp devaddr_range_from_web(%{"start_addr" => s, "end_addr" => e}) do
    {s, e}
  end

  def from_db(db_route = %DB.Route{}) do
    %__MODULE__{
      net_id: db_route.net_id,
      lns_address: db_route.lns_address,
      protocol: db_route.protocol,
      euis:
        Enum.map(db_route.euis, fn db_eui ->
          %{app_eui: db_eui.app_eui, dev_eui: db_eui.dev_eui}
        end),
      devaddr_ranges:
        Enum.map(db_route.devaddr_ranges, fn range -> {range.start_addr, range.end_addr} end)
    }
  end
end
