defmodule Excloud.Accounts.Account.Type do
  @moduledoc """
  Persists account type atoms as strings without creating atoms from input.

  String values are accepted only when the corresponding atom already exists.
  Account type atoms must therefore be declared in application code before
  persisted accounts of those types can be loaded.
  """

  use Ecto.Type

  @impl true
  def type, do: :string

  @impl true
  def cast(value) when is_atom(value), do: {:ok, value}
  def cast(value) when is_binary(value), do: load(value)
  def cast(_value), do: :error

  @impl true
  def dump(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  def dump(_value), do: :error

  @impl true
  def load(value) when is_binary(value) do
    {:ok, String.to_existing_atom(value)}
  rescue
    ArgumentError -> :error
  end

  def load(_value), do: :error
end
