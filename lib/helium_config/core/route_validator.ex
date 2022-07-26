defmodule HeliumConfig.Core.RouteValidator do
  @moduledoc """
  Functions for validating Core.Route structs.
  """

  import HeliumConfig.Core.Validator

  def validate(fields) when is_map(fields) do
    errors =
      []
      |> require(fields, :organization_id, &validate_org_id/1)
      |> require(fields, :net_id, &validate_net_id/1)

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end

  defp validate_org_id(id) when is_integer(id) do
    check(id > 0, {:error, "organization_id must be a non-zero integer"})
  end

  defp validate_org_id(_id), do: {:error, "organization_id must be a non-zero integer"}

  defp validate_net_id(id) when is_integer(id) do
    check(id > 0, {:error, "net_id must be a positive non-zero integer"})
  end

  defp validate_net_id(_id), do: {:error, "net_id must be a positive non-zero integer"}
end
