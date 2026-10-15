defmodule Excloud.Accounts.User do
  @moduledoc """
  Stores authentication data and references one shared account.

  `id` is the internal database key. `external_id` is a UUIDv7 generated on
  insertion for use outside the database.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Excloud.Types.EncryptedString

  @type t :: %__MODULE__{}

  @max_verification_key_bytes 344

  schema "users" do
    field :login, :string
    field :email, :string
    field :hashed_password, :string, redact: true
    field :verification_key, EncryptedString, redact: true
    field :external_id, Ecto.UUID, autogenerate: [version: 7]

    belongs_to :account, Excloud.Accounts.Account

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Validates a user's login, email, and stored credentials.

  For a new user, set `hashed_password` on the struct using trusted password
  hashing code before calling this function, and set `account_id` to an existing
  account using trusted application code. Set `verification_key` through trusted
  code as well. This changeset only accepts the login and email from attributes.
  Logins are case-sensitive; emails are trimmed and lowercased. Email and
  verification keys are optional. Verification keys are encrypted for storage
  and may contain at most 344 bytes of plaintext.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:login, :email])
    |> update_change(:login, &String.trim/1)
    |> update_change(:email, &String.downcase(String.trim(&1)))
    |> validate_required([:login, :hashed_password, :account_id])
    |> validate_length(:login, max: 255)
    |> validate_format(:login, ~r/\A\S+\z/u, message: "must not contain whitespace")
    |> validate_length(:email, max: 254)
    |> validate_format(:email, ~r/\A[^@,;\s]+@[^@,;\s]+\z/u,
      message: "must have the @ sign and no spaces"
    )
    |> validate_verification_key_length()
    |> unique_constraint(:login)
    |> unique_constraint(:email)
    |> unique_constraint(:external_id)
    |> foreign_key_constraint(:account_id)
    |> check_constraint(:external_id, name: :users_external_id_uuid_v7)
  end

  defp validate_verification_key_length(changeset) do
    case get_field(changeset, :verification_key) do
      key when is_binary(key) and byte_size(key) > @max_verification_key_bytes ->
        add_error(changeset, :verification_key, "should be at most %{count} byte(s)",
          count: @max_verification_key_bytes,
          validation: :length,
          kind: :max
        )

      _valid_or_missing ->
        changeset
    end
  end
end
