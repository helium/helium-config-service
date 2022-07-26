alias HeliumConfig.Repo
alias HeliumConfig.Core.Organization, as: CoreOrg
alias HeliumConfig.DB.Organization

params =
  %{
    oui: 3,
    owner_wallet_id: "owner",
    payer_wallet_id: "payer",
    routes: [
      %{
        net_id: 7,
        lns_address: "lns.address.com",
        protocol: :http,
        euis: ["eui1"],
        devaddr_ranges: [
          {<<200, 0, 0, 0>>, <<200, 0, 0, 100>>}
        ]
      }
    ]
  }
  |> CoreOrg.new()
  |> HeliumConfig.save_organization()

Repo.get(Organization, 3) |> Repo.preload(:routes) |> Repo.preload(routes: :devaddr_ranges)
