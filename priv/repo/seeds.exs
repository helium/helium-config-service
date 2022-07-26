# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     HeliumConfig.Repo.insert!(%HeliumConfig.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias HeliumConfig.Core.Organization

[
  %{
    oui: 7,
    owner_wallet_id: "owner",
    payer_wallet_id: "payer",
    routes: [
      %{
        net_id: 7,
        lns_address: "lns1.testdomain.com",
        protocol: :gwmp,
        euis: [
          %{
            dev_eui: 1,
            app_eui: 2
          }
        ],
        devaddr_ranges: [
          {100, 200},
          {300, 350}
        ]
      }
    ]
  },
  %{
    oui: 8,
    owner_wallet_id: "owner",
    payer_wallet_id: "payer",
    routes: [
      %{
        net_id: 8,
        lns_address: "lns2.testdomain.com",
        protocol: :http,
        euis: [
          %{
            dev_eui: 3,
            app_eui: 4
          }
        ],
        devaddr_ranges: [
          {400, 500},
          {600, 650}
        ]
      }
    ]
  }
]
|> Enum.map(fn params ->
  params
  |> Organization.new()
  |> HeliumConfig.save_organization()
end)
