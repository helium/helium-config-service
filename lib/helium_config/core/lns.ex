defmodule HeliumConfig.Core.Lns do
  @moduledoc """
  Utility functions for converting Core LNS models to and from JSON and DB representations.
  """
  alias HeliumConfig.Core
  alias HeliumConfig.DB

  def from_proto({:http_roaming, proto}) do
    %Core.HttpRoamingLns{
      host: proto.ip,
      port: proto.port
    }
  end

  def from_proto({:gwmp, proto}) do
    %Core.GwmpLns{
      host: proto.ip,
      port: proto.port
    }
  end

  def from_proto({:helium_router, proto}) do
    %Core.HeliumRouterLns{
      host: proto.ip,
      port: proto.port
    }
  end

  def from_web(json = %{"type" => "http_roaming"}) do
    json
    |> Enum.reduce(
      %Core.HttpRoamingLns{},
      fn
        {"type", _}, roaming ->
          roaming

        {"host", host}, roaming ->
          Map.put(roaming, :host, host)

        {"port", port}, roaming ->
          Map.put(roaming, :port, port)

        {"dedupe_window", window}, roaming ->
          Map.put(roaming, :dedupe_window, window)

        {"auth_header", header}, roaming ->
          Map.put(roaming, :auth_header, header)
      end
    )
  end

  def from_web(json = %{"type" => "gwmp"}) do
    json
    |> Enum.reduce(
      %Core.GwmpLns{},
      fn
        {"type", _}, gwmp ->
          gwmp

        {"host", host}, gwmp ->
          Map.put(gwmp, :host, host)

        {"port", port}, gwmp ->
          Map.put(gwmp, :port, port)
      end
    )
  end

  def from_web(json = %{"type" => "helium_router"}) do
    json
    |> Enum.reduce(
      %Core.HeliumRouterLns{},
      fn
        {"type", _}, gwmp ->
          gwmp

        {"host", host}, gwmp ->
          Map.put(gwmp, :host, host)

        {"port", port}, gwmp ->
          Map.put(gwmp, :port, port)
      end
    )
  end

  def from_db(lns = %DB.Lns{type: :http_roaming}) do
    %Core.HttpRoamingLns{
      host: lns.host,
      port: lns.port,
      dedupe_window: Map.get(lns.protocol_params, "dedupe_window"),
      auth_header: Map.get(lns.protocol_params, "auth_header")
    }
  end

  def from_db(lns = %DB.Lns{type: :gwmp}) do
    %Core.GwmpLns{
      host: lns.host,
      port: lns.port
    }
  end

  def from_db(lns = %DB.Lns{type: :helium_router}) do
    %Core.HeliumRouterLns{
      host: lns.host,
      port: lns.port
    }
  end
end
