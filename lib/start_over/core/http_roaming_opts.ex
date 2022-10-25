defmodule StartOver.Core.HttpRoamingOpts do
  defstruct [:dedupe_window, :auth_header]

  alias Proto.Helium.Config.ProtocolHttpRoamingV1

  def new(params \\ %{}) do
    %__MODULE__{
      dedupe_window: Map.get(params, :dedupe_window),
      auth_header: Map.get(params, :auth_header)
    }
  end

  def from_proto(%{__struct__: ProtocolHttpRoamingV1}), do: %__MODULE__{}

  def from_web(%{"type" => "http_roaming"} = fields) do
    fields
    |> Enum.reduce(%__MODULE__{}, fn
      {"type", "http_roaming"}, acc -> acc
      {"dedupe_window", window}, acc -> Map.put(acc, :dedupe_window, window)
      {"auth_header", auth}, acc -> Map.put(acc, :auth_header, auth)
    end)
  end

  def from_db(db_opts) do
    db_opts
    |> Enum.reduce(%__MODULE__{}, fn
      {"dedupe_window", window}, acc -> Map.put(acc, :dedupe_window, window)
      {"auth_header", auth}, acc -> Map.put(acc, :auth_header, auth)
    end)
  end
end
