defmodule Excloud.Accounts.Account do
  @moduledoc """
  Stores a shared account type and defines the account behaviour.

  `type` is an atom that will identify the module implementing this behaviour.
  It is persisted as a string and loaded only as an existing atom. Concrete
  account types and their module mapping are defined separately.
  Authentication data remains in `Excloud.Accounts.User`.
  Multiple users can reference the same account, with one account per type.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Excloud.Accounts.Account.Type
  alias Excloud.Accounts.User

  @type t :: %__MODULE__{}

  @doc "Returns the base role provided by the account type's implementation."
  @callback role(t()) :: atom()

  schema "accounts" do
    field :type, Type

    has_many :users, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc "Validates a shared account type."
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:type])
    |> validate_required([:type])
    |> unique_constraint(:type)
    |> no_assoc_constraint(:users)
  end
end
