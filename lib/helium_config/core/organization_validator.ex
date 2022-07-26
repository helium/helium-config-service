defmodule HeliumConfig.Core.OrganizationValidator do
  @moduledoc """
  Functions for validating Core.Organization structs.
  """

  import HeliumConfig.Core.Validator

  alias HeliumConfig.Core.RouteValidator

  def validate(fields) when is_map(fields) do
    errors =
      []
      |> require(fields, :oui, &validate_oui/1)
      |> require(fields, :owner_wallet_id, &validate_owner_wallet_id/1)
      |> require(fields, :payer_wallet_id, &validate_payer_wallet_id/1)
      |> require(fields, :routes, &validate_routes/1)

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end

  def validate_oui(oui) when is_integer(oui) do
    if oui <= 0 do
      {:error, "oui must be a non-negative integer"}
    else
      :ok
    end
  end

  def validate_oui(_), do: {:error, "oui must be a non-negative integer"}

  def validate_owner_wallet_id(id), do: validate_wallet_id(id, "owner")

  def validate_payer_wallet_id(id), do: validate_wallet_id(id, "payer")

  def validate_wallet_id(id, who) when is_binary(id) do
    if String.match?(id, ~r{\S*}) do
      {:error, "#{who} wallet ID cannot be blank"}
    else
      :ok
    end
  end

  def validate_wallet_id(_id, who), do: {:error, "#{who} wallet ID must be a non-empty string"}

  def validate_routes(routes) when is_list(routes) do
    case routes_errors(routes, 0, []) do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  defp routes_errors([], _idx, errors), do: errors

  defp routes_errors([route | rest], idx, error_acc) do
    errors =
      case RouteValidator.validate(route) do
        {:errors, route_errors} ->
          Enum.map(route_errors, fn {field, msg} -> "routes[#{idx}] #{field} #{msg}" end)

        :ok ->
          []
      end

    routes_errors(rest, idx + 1, error_acc ++ errors)
  end
end
