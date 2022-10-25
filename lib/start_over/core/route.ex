defmodule StartOver.Core.Route do
  @enforce_keys [:net_id, :server, :max_copies, :euis, :devaddr_ranges]

  defstruct [:id, :oui, :net_id, :server, max_copies: 1, euis: [], devaddr_ranges: []]

  alias StartOver.Core.RouteServer
  alias StartOver.DB

  def new(params \\ %{}) do
    server =
      params
      |> Map.get(:server, %{})
      |> RouteServer.new()

    params = Map.put(params, :server, server)

    struct!(__MODULE__, params)
  end

  def from_db(%DB.Route{} = db_route) do
    %__MODULE__{
      id: db_route.id,
      oui: db_route.oui,
      net_id: db_route.net_id,
      max_copies: db_route.max_copies,
      server: RouteServer.from_db(db_route.server),
      euis: euis_from_db(db_route.euis),
      devaddr_ranges: devaddr_ranges_from_db(db_route.devaddr_ranges)
    }
  end

  def euis_from_db(euis) do
    Enum.map(euis, fn %DB.EuiPair{app_eui: a, dev_eui: d} ->
      %{
        app_eui: Decimal.to_integer(a),
        dev_eui: Decimal.to_integer(d)
      }
    end)
  end

  def devaddr_ranges_from_db(ranges) do
    Enum.map(ranges, fn %DB.DevaddrRange{start_addr: s, end_addr: e} -> {s, e} end)
  end

  def from_proto(%{__struct__: Proto.Helium.Config.RouteV1} = route) do
    server = RouteServer.from_proto(route.server)
    euis = euis_from_proto(route.euis)
    devaddr_ranges = devaddr_ranges_from_proto(route.devaddr_ranges)

    %__MODULE__{
      oui: route.oui,
      net_id: route.net_id,
      max_copies: route.max_copies,
      server: server,
      euis: euis,
      devaddr_ranges: devaddr_ranges
    }
  end

  def euis_from_proto(euis) do
    euis
    |> Enum.map(fn %{__struct__: Proto.Helium.Config.EuiV1, app_eui: app, dev_eui: dev} ->
      %{app_eui: app, dev_eui: dev}
    end)
  end

  def devaddr_ranges_from_proto(devaddr_ranges) do
    devaddr_ranges
    |> Enum.map(fn %{__struct__: Proto.Helium.Config.DevaddrRangeV1, start_addr: s, end_addr: e} ->
      {s, e}
    end)
  end

  def from_web(json_params) do
    params =
      json_params
      |> Enum.reduce(%{}, fn
        {"id", id}, acc ->
          Map.put(acc, :id, id)

        {"oui", id}, acc ->
          Map.put(acc, :oui, oui_from_web(id))

        {"net_id", id}, acc ->
          Map.put(acc, :net_id, net_id_from_web(id))

        {"max_copies", max}, acc ->
          Map.put(acc, :max_copies, max_copies_from_web(max))

        {"server", server}, acc ->
          Map.put(acc, :server, RouteServer.from_web(server))

        {"euis", euis}, acc ->
          Map.put(acc, :euis, euis_from_web(euis))

        {"devaddr_ranges", ranges}, acc ->
          Map.put(acc, :devaddr_ranges, devaddr_ranges_from_web(ranges))
      end)

    struct!(__MODULE__, params)
  end

  def oui_from_web(id) when is_binary(id) do
    String.to_integer(id, 16)
  end

  def oui_from_web(id) when is_integer(id), do: id

  def max_copies_from_web(max) when is_binary(max), do: String.to_integer(max, 10)

  def max_copies_from_web(max) when is_integer(max), do: max

  def net_id_from_web(id) when is_binary(id) do
    String.to_integer(id, 16)
  end

  def net_id_from_web(id) when is_integer(id), do: id

  def euis_from_web(web_euis) do
    Enum.map(web_euis, &eui_pair_from_web/1)
  end

  def eui_pair_from_web(%{"app_eui" => app, "dev_eui" => dev})
      when is_binary(app) and is_binary(dev) do
    %{app_eui: String.to_integer(app, 16), dev_eui: String.to_integer(dev, 16)}
  end

  def eui_pair_from_web(%{"app_eui" => app, "dev_eui" => dev})
      when is_integer(app) and is_integer(dev) do
    %{app_eui: app, dev_eui: dev}
  end

  def devaddr_ranges_from_web(ranges) do
    Enum.map(ranges, &devaddr_range_from_web/1)
  end

  def devaddr_range_from_web(%{"start_addr" => start_addr, "end_addr" => end_addr})
      when is_binary(start_addr) and is_binary(end_addr) do
    {String.to_integer(start_addr, 16), String.to_integer(end_addr, 16)}
  end

  def devaddr_range_from_web(%{"start_addr" => start_addr, "end_addr" => end_addr})
      when is_integer(start_addr) and is_integer(end_addr) do
    {start_addr, end_addr}
  end
end
