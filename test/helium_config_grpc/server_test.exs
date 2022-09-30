defmodule HeliumConfigGRPC.ServerTest do
  use HeliumConfig.DataCase

  alias HeliumConfig.Core.GwmpLns
  alias HeliumConfig.Core.HttpRoamingLns
  alias HeliumConfig.Core.Organization
  alias HeliumConfig.Core.Route
  alias HeliumConfigGRPC.Stub

  alias Proto.Helium.Config.RoutesReqV1, as: RoutesRequest

  describe "route_updates" do
    setup [:create_orgs]

    test "returns a stream of Routes", %{orgs: _orgs} do
      {:ok, channel} = GRPC.Stub.connect("localhost:50051")
      req1 = RoutesRequest.new()
      {:ok, responses} = Stub.route_updates(channel, req1)

      responses
      |> Enum.take(1)
      |> Enum.each(fn
        {:ok, routes_res} ->
          Enum.map(routes_res.routes, &Route.from_proto/1)
      end)
    end
  end

  defp create_orgs(ctx) do
    orgs =
      [
        %{
          oui: 1,
          owner_wallet_id: "owner1_id",
          payer_wallet_id: "payer1_id",
          routes: [
            %{
              net_id: 1,
              lns: %HttpRoamingLns{
                host: "lns1.testdomain.com",
                port: 4000,
                dedupe_window: 2000,
                auth_header: "x-helium-auth"
              },
              euis: [
                %{
                  dev_eui: 100,
                  app_eui: 200
                }
              ],
              devaddr_ranges: [
                {150, 250},
                {350, 450}
              ]
            }
          ]
        },
        %{
          oui: 2,
          owner_wallet_id: "owner2_id",
          payer_wallet_id: "payer2_id",
          routes: [
            %{
              net_id: 2,
              lns: %GwmpLns{
                host: "lns2.testdomain.com",
                port: 8888
              },
              euis: [
                %{
                  dev_eui: 300,
                  app_eui: 400
                }
              ],
              devaddr_ranges: [
                {550, 650},
                {750, 850}
              ]
            }
          ]
        }
      ]
      |> Enum.map(&Organization.new/1)

    [:ok, :ok] =
      Enum.map(orgs, fn params ->
        HeliumConfig.save_organization(params)
      end)

    Map.put(ctx, :orgs, orgs)
  end
end
