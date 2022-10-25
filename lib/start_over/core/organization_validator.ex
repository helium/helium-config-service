defmodule StartOver.Core.OrganizationValidator do
  import StartOver.Core.Validator

  alias StartOver.Core.InvalidDataError
  alias StartOver.Core.RouteValidator

  def validate!(%StartOver.Core.Organization{} = fields) do
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
      |> require(fields, :owner_wallet_id, &validate_wallet_id/1)
      |> require(fields, :payer_wallet_id, &validate_wallet_id/1)
      |> require(fields, :routes, &validate_routes/1)

    case errors do
      [] -> :ok
      _ -> {:errors, errors}
    end
  end

  def validate_oui(oui) do
    with :ok <-
           check(is_integer(oui) and oui > 0, {:error, "oui must be a positive unsigned integer"}) do
      :ok
    end
  end

  def validate_wallet_id(id) do
    with :ok <- check(is_binary(id), {:error, "wallet ID must be a string"}) do
      :ok
    end
  end

  def validate_routes(routes) do
    with :ok <- check(is_list(routes), {:error, "routes must be a list"}),
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
