defmodule HeliumConfigGRPC.OrganizationView do
  @moduledoc """
  Provides functions to convert HeliumConfig.Core structs to maps suitable for encoding protobuf messages.
  """

  alias HeliumConfig.Core.Organization
  alias HeliumConfig.Core.Route

  def organization_params(org = %Organization{}) do
    %{
      oui: org.oui,
      owner_wallet_id: org.owner_wallet_id,
      payer_wallet_id: org.payer_wallet_id,
      routes: Enum.map(org.routes, &route_params/1)
    }
  end

  def route_params(route = %Route{}) do
    %{
      net_id: route.net_id,
      lns_address: route.lns_address,
      protocol: route.protocol,
      euis: route.euis,
      devaddr_ranges: Enum.map(route.devaddr_ranges, &devaddr_range_params/1)
    }
  end

  def devaddr_range_params({s, e}) do
    %{
      start: s,
      end: e
    }
  end
end
