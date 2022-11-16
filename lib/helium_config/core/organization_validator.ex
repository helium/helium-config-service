defmodule HeliumConfig.Core.OrganizationValidator do
  import HeliumConfig.Core.Validator

  alias HeliumConfig.Core.InvalidDataError
  alias HeliumConfig.Core.RouteValidator

  def validate!(%HeliumConfig.Core.Organization{} = fields) do
    case validate(fields) do
      :ok ->
        fields

      {:errors, errors} ->
        raise InvalidDataError, message: "invalid organization: #{inspect(errors)}"
    end
  end

  def validate(fields) when is_map(fields) do
    errors =
      []
      |> require(fields, :oui, &validate_oui/1)
      |> require(fields, :owner_pubkey, &validate_pubkey/1)
      |> require(fields, :payer_pubkey, &validate_pubkey/1)
      |> require(fields, :routes, &validate_routes/1)

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end

  def validate_oui(_oui) do
    # TODO: check with the database for the next available OUI to be assigned
    # with :ok <-
    # check(is_integer(oui) and oui > 0, {:error, "oui must be a positive unsigned integer"}) do
    :ok
    # end
  end

  def validate_pubkey({:ecc_compact, _}), do: :ok

  def validate_pubkey({:ed25519, _}), do: :ok

  def validate_pubkey(_), do: {:error, "pubkey must be type :ecc_compact or :ed25519"}

  def validate_routes(nil), do: :ok

  def validate_routes(routes) do
    with :ok <- check(is_list(routes), {:error, "routes must be a list or nil"}),
         :ok <- all_routes_valid?(routes) do
      :ok
    end
  end

  def all_routes_valid?(routes) do
    results = Enum.map(routes, &RouteValidator.validate/1)

    case Enum.all?(results, &(:ok == &1)) do
      true -> :ok
      false -> {:errors, results}
    end
  end
end
