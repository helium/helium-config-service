defmodule StartOver.Core.Validator do
  @moduledoc """
  Common functions for validating Core data structures.

  This module is intended to be imported by other modules that
  validate specific Core data structures.

  """

  def require(errors, fields, field_name, validator) do
    present = Map.has_key?(fields, field_name)
    check_required_field(present, fields, errors, field_name, validator)
  end

  def optional(errors, fields, field_name, validator) do
    if Map.has_key?(fields, field_name) do
      require(errors, fields, field_name, validator)
    else
      errors
    end
  end

  def check(_valid = true, _message), do: :ok
  def check(_valid = false, message), do: message

  defp check_required_field(_present = true, fields, errors, field_name, f) do
    valid =
      fields
      |> Map.fetch!(field_name)
      |> f.()

    check_field(valid, errors, field_name)
  end

  defp check_required_field(_present, _fields, errors, field_name, _f) do
    errors ++ [{field_name, "is required"}]
  end

  defp check_field(:ok, errors, _field_name), do: errors

  defp check_field({:error, message}, errors, field_name) do
    errors ++ [{field_name, message}]
  end

  defp check_field({:errors, messages}, errors, field_name) do
    errors ++ Enum.map(messages, &{field_name, &1})
  end
end
