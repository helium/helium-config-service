defmodule HeliumConfig.Core.HttpRoamingLns do
  @moduledoc """

  Core representation of a LoRaWAN network server that supports HTTP roaming.

  """

  defstruct [:host, :port, :auth_header, :dedupe_window]
end
