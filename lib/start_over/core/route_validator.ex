defmodule StartOver.Core.RouteValidator do
  import StartOver.Core.Validator

  alias StartOver.Core.NetID
  alias StartOver.Core.Devaddr

  @net_id_max_value 16_777_215

  def validate(fields) when is_map(fields) do
    errors =
      []
      |> require(fields, :net_id, &validate_net_id/1)
      |> require(fields, :devaddr_ranges, &validate_devaddr_ranges/1)
      |> validate_net_id_and_devaddr_ranges(fields)

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end

  def validate_net_id(id) do
    with :ok <- check(is_integer(id), {:error, "net_id must be an integer"}),
         :ok <- check(id > 0, {:error, "net_id must be greater than 0"}),
         :ok <-
           check(
             id <= @net_id_max_value,
             {:error, "net_id must be less than or equal to #{@net_id_max_value}"}
           ) do
      :ok
    end
  end

  def validate_devaddr_ranges(ranges) do
    errors =
      ranges
      |> Enum.reduce([], fn range, acc ->
        case validate_devaddr_range(range) do
          :ok -> acc
          {:error, e} -> [{:error, e} | acc]
        end
      end)

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end

  def validate_devaddr_range({start_bin, end_bin})
      when is_integer(start_bin) and is_integer(end_bin) do
    with start_addr <- Devaddr.from_integer(start_bin),
         end_addr <- Devaddr.from_integer(end_bin),
         :ok <-
           check(
             start_addr.nwk_id == end_addr.nwk_id,
             {:error,
              "start and end addr in {#{start_addr}, #{end_addr}} must have the same NwkID"}
           ),
         :ok <-
           check(
             start_addr.nwk_addr < end_addr.nwk_addr,
             {:error,
              "start NwkAddr must be less than end NwkAddr in {#{start_addr}, #{end_addr}}"}
           ) do
      :ok
    end
  end

  def validate_devaddr_range(other),
    do: {:error, "devaddr range must be a tuple of 32-bit binaries (#{inspect(other)})"}

  def validate_net_id_and_devaddr_ranges([_ | _] = errors, _fields), do: errors

  def validate_net_id_and_devaddr_ranges([], fields) do
    net_id_bin = Map.fetch!(fields, :net_id)
    ranges = Map.fetch!(fields, :devaddr_ranges)

    Enum.reduce(ranges, [], fn range, acc ->
      case validate_net_id_and_devaddr_range(net_id_bin, range) do
        {:error, e} -> acc ++ [e]
        :ok -> acc
      end
    end)
  end

  def validate_net_id_and_devaddr_range(net_id_bin, {start_addr_bin, end_addr_bin}) do
    with net_id <- NetID.from_integer(net_id_bin),
         start_addr <- Devaddr.from_integer(start_addr_bin),
         end_addr <- Devaddr.from_integer(end_addr_bin),
         :ok <-
           check(
             start_addr.nwk_id == net_id.nwk_id,
             {:error,
              "start addr in {#{start_addr}, #{end_addr}} must have the same NwkID as #{net_id}"}
           ),
         :ok <-
           check(
             end_addr.nwk_id == net_id.nwk_id,
             {:error,
              "end addr in {#{start_addr}, #{end_addr}} must have the same NwkID as #{net_id}"}
           ) do
      :ok
    end
  end
end
