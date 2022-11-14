defmodule HeliumConfig.Repo.Migrations.DecomposeDevaddrRanges do
  use Ecto.Migration

  alias HeliumConfig.Core.Devaddr

  import Ecto.Query

  def up do
    alter table("route_devaddr_ranges") do
      add :type, :string
      add :nwk_id, :integer
      add :start_nwk_addr, :integer
      add :end_nwk_addr, :integer
    end

    flush()

    transform_data_up()

    alter table("route_devaddr_ranges") do
      remove :start_addr
      remove :end_addr

      modify :type, :string, null: false
      modify :nwk_id, :integer, null: false
      modify :start_nwk_addr, :integer, null: false
      modify :end_nwk_addr, :integer, null: false
    end
  end

  def transform_data_up do
    from(r in "route_devaddr_ranges", select: [:id, :start_addr, :end_addr])
    |> repo().all()
    |> Enum.map(fn %{
                     id: id,
                     start_addr: start_addr,
                     end_addr: end_addr
                   } ->
      %{type: type, nwk_id: nwk_id, nwk_addr: start_nwk_addr} = Devaddr.from_integer(start_addr)
      %{nwk_addr: end_nwk_addr} = Devaddr.from_integer(end_addr)

      type = Atom.to_string(type)

      repo().query!(
        "update route_devaddr_ranges set type = $1, nwk_id = $2, start_nwk_addr = $3, end_nwk_addr = $4 where id = $5",
        [type, nwk_id, start_nwk_addr, end_nwk_addr, id]
      )
    end)
  end

  def down do
    alter table("route_devaddr_ranges") do
      add :start_addr, :integer
      add :end_addr, :integer
    end

    flush()

    transform_data_down()

    alter table("route_devaddr_ranges") do
      remove :type
      remove :nwk_id
      remove :start_nwk_addr
      remove :end_nwk_addr

      modify :start_addr, :integer, null: false
      modify :end_addr, :integer, null: false
    end
  end

  def transform_data_down do
    from(r in "route_devaddr_ranges",
      select: [:id, :type, :nwk_id, :start_nwk_addr, :end_nwk_addr]
    )
    |> repo().all()
    |> Enum.map(fn %{
                     id: id,
                     type: type,
                     nwk_id: nwk_id,
                     start_nwk_addr: start_nwk_addr,
                     end_nwk_addr: end_nwk_addr
                   } ->
      type = String.to_atom(type)

      start_int =
        type
        |> Devaddr.new(nwk_id, start_nwk_addr)
        |> Devaddr.to_integer()

      end_int =
        type
        |> Devaddr.new(nwk_id, end_nwk_addr)
        |> Devaddr.to_integer()

      repo().query!(
        "update route_devaddr_ranges set start_addr = $1, end_addr = $2 where id = $3",
        [start_int, end_int, id]
      )
    end)
  end
end
