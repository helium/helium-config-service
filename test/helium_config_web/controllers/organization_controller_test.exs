defmodule HeliumConfigWeb.OrganizationControllerTest do
  use HeliumConfigWeb.ConnCase

  describe "Organizations controller" do
    setup [:valid_org_params]

    test "POST /organization creates a valid organization given valid parameters",
         %{
           valid_org_params: params,
           conn: conn
         } do
      conn =
        conn
        |> post("/api/v1/organizations", %{"organization" => params})

      assert(conn.status == 201)
    end

    defp valid_org_params(_) do
      params = %{
        "oui" => 7,
        "owner_wallet_id" => "owner_wallet",
        "payer_wallet_id" => "payer_wallet",
        "routes" => [
          %{
            "net_id" => 7,
            "lns_address" => "lns1.testdomain.com",
            "protocol" => "http",
            "euis" => [
              %{
                "dev_eui" => 100,
                "app_eui" => 200
              }
            ],
            "devaddr_ranges" => [
              %{
                "start_addr" => 100,
                "end_addr" => 150
              },
              %{
                "start_addr" => 250,
                "end_addr" => 300
              }
            ]
          }
        ]
      }

      %{
        valid_org_params: params
      }
    end
  end
end
