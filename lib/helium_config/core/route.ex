defmodule HeliumConfig.Core.Route do
  @moduledoc """
  Data module representing a Route.
  """
  alias HeliumConfig.Core.Lns
  alias HeliumConfig.DB

  # A string containing a DNS hostname or IP address
  @type host_string :: String.t()

  @type eui_pair :: %{
          required(:app_eui) => integer,
          required(:dev_eui) => integer
        }

  @type devaddr_range :: %{
          required(:start_addr) => integer,
          required(:end_addr) => integer
        }

  @type t :: %__MODULE__{
          net_id: integer,
          euis: [eui_pair],
          devaddr_ranges: [devaddr_range]
        }

  # Valid keys for json_eui are:
  # "app_eui" => integer,
  # "dev_eui" => integer
  @type json_eui :: %{String.t() => integer}

  # Valid keys for json_devaddr_range are:
  # "start_addr" => integer,
  # "end_addr" => integer
  @type json_devaddr_range :: %{String.t() => integer}

  # Valid keys for json_params are:
  # "net_id" => integer,
  # "euis" => [json_eui],
  # "devaddr_ranges" => [json_devaddr_range]
  @type json_params :: %{String.t() => any()}

  defstruct net_id: nil,
            lns: nil,
            euis: [],
            devaddr_ranges: []

  @spec new(json_params) :: t
  def new(fields \\ %{}) do
    struct!(__MODULE__, fields)
  end

  def from_web(web_fields = %{}) do
    params =
      web_fields
      |> Enum.reduce(%{}, fn
        {"net_id", net_id}, acc ->
          Map.put(acc, :net_id, net_id)

        {"euis", euis}, acc ->
          Map.put(acc, :euis, Enum.map(euis, &eui_from_web/1))

        {"devaddr_ranges", ranges}, acc ->
          Map.put(acc, :devaddr_ranges, Enum.map(ranges, &devaddr_range_from_web/1))

        {"lns", lns}, acc ->
          Map.put(acc, :lns, Lns.from_web(lns))
      end)

    struct!(__MODULE__, params)
  end

  defp eui_from_web(%{"dev_eui" => dev, "app_eui" => app}) do
    %{
      dev_eui: dev,
      app_eui: app
    }
  end

  defp devaddr_range_from_web(%{"start_addr" => s, "end_addr" => e}) do
    {String.to_integer(s, 16), String.to_integer(e, 16)}
  end

  def from_db(db_route = %DB.Route{}) do
    %__MODULE__{
      net_id: db_route.net_id,
      lns: Lns.from_db(db_route.lns),
      euis:
        Enum.map(db_route.euis, fn db_eui ->
          %{app_eui: db_eui.app_eui, dev_eui: db_eui.dev_eui}
        end),
      devaddr_ranges:
        Enum.map(db_route.devaddr_ranges, fn range -> {range.start_addr, range.end_addr} end)
    }
  end

  def from_proto(proto_route = %{__struct__: Proto.Helium.Config.RouteV1}) do
    %__MODULE__{
      net_id: proto_route.net_id,
      lns: Lns.from_proto(proto_route.protocol),
      euis:
        Enum.map(proto_route.euis, fn e ->
          %{app_eui: e.app_eui, dev_eui: e.dev_eui}
        end),
      devaddr_ranges:
        Enum.map(proto_route.devaddr_ranges, fn %{start_addr: s, end_addr: e} ->
          {s, e}
        end)
    }
  end
end
