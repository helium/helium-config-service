defmodule HeliumConfig.Core.GwmpOpts do
  defstruct mapping: []

  def new(%{mapping: mappings}) do
    %__MODULE__{
      mapping: mappings
    }
  end

  def from_db(%{"mapping" => mappings}) do
    %__MODULE__{
      mapping:
        Enum.map(mappings, fn %{"region" => region, "port" => port} ->
          {region_from_web(region), port}
        end)
    }
  end

  def from_proto(%{__struct__: Proto.Helium.Config.ProtocolGwmpV1} = gwmp) do
    %__MODULE__{
      mapping: Enum.map(gwmp.mapping, &mapping_from_proto/1)
    }
  end

  def mapping_from_proto(%{__struct__: Proto.Helium.Config.ProtocolGwmpMappingV1} = mapping) do
    {mapping.region, mapping.port}
  end

  def from_web(%{"type" => "gwmp", "mapping" => mappings}) do
    %__MODULE__{
      mapping:
        Enum.map(mappings, fn
          %{"region" => region, "port" => port} -> {region_from_web(region), port}
        end)
    }
  end

  def region_from_web("US915"), do: :US915
  def region_from_web("EU868"), do: :EU868
  def region_from_web("EU433"), do: :EU433
  def region_from_web("CN470"), do: :CN470
  def region_from_web("CN779"), do: :CN779
  def region_from_web("AU915"), do: :AU915
  def region_from_web("AS923_1"), do: :AS923_1
  def region_from_web("KR920"), do: :KR920
  def region_from_web("IN865"), do: :IN865
  def region_from_web("AS923_2"), do: :AS923_2
  def region_from_web("AS923_3"), do: :AS923_3
  def region_from_web("AS923_4"), do: :AS923_4
  def region_from_web("AS923_1A"), do: :AS923_1A
  def region_from_web("AS923_1B"), do: :AS923_1B
  def region_from_web("AS923_1C"), do: :AS923_1C
  def region_from_web("AS923_1D"), do: :AS923_1D
  def region_from_web("AS923_1E"), do: :AS923_1E
  def region_from_web("AS923_1F"), do: :AS923_1F
  def region_from_web("AU915_SB1"), do: :AU915_SB1
  def region_from_web("AU915_SB2"), do: :AU915_SB2
  def region_from_web("EU868_A"), do: :EU868_A
  def region_from_web("EU868_B"), do: :EU868_B
  def region_from_web("EU868_C"), do: :EU868_C
  def region_from_web("EU868_D"), do: :EU868_D
  def region_from_web("EU868_E"), do: :EU868_E
  def region_from_web("EU868_F"), do: :EU868_F
  def region_from_web("CD900_1A"), do: :CD900_1A
end
