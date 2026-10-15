defmodule Excloud.Repo.Migrations.EncryptUserVerificationKeys do
  @moduledoc false

  use Ecto.Migration

  import Ecto.Query, only: [from: 2, select: 3]

  require Logger

  # Freeze the encryption format so future type changes do not affect this migration.
  @key_salt "excloud:encrypted_string:secretbox:v1"

  def up do
    alter table(:users) do
      modify :verification_key, :string, size: 512
    end

    flush()
    transform_keys(&encrypt/2, 512)
  end

  def down do
    transform_keys(&decrypt!/2, 255)

    alter table(:users) do
      modify :verification_key, :string, size: 255
    end
  end

  defp transform_keys(transform, limit) do
    endpoint_config = Application.fetch_env!(:excloud, ExcloudWeb.Endpoint)
    secret = Keyword.fetch!(endpoint_config, :secret_key_base)
    key = :crypto.pbkdf2_hmac(:sha256, secret, @key_salt, 1000, 32)

    query = from(user in "users", where: not is_nil(user.verification_key))

    query
    |> select([user], {user.id, user.verification_key})
    |> repo().stream(log: false)
    |> Enum.each(fn {id, value} ->
      transformed = transform.(value, key)

      if length(String.to_charlist(transformed)) > limit do
        fail_migration!("A verification key exceeds the target column size")
      end

      repo().query!(
        "UPDATE users SET verification_key = $1 WHERE id = $2",
        [transformed, id],
        log: false
      )
    end)
  end

  defp encrypt(value, key) do
    nonce = :enacl.randombytes(24)
    box = :enacl.secretbox(value, nonce, key)
    Base.encode64(nonce <> box)
  end

  defp decrypt!(value, key) do
    case Base.decode64(value) do
      {:ok, <<nonce::binary-size(24), box::binary>>} when byte_size(box) >= 16 ->
        case :enacl.secretbox_open(box, nonce, key) do
          {:ok, plaintext} -> plaintext
          _error -> fail_migration!("Cannot decrypt a stored verification key")
        end

      _error ->
        fail_migration!("Cannot decrypt a stored verification key")
    end
  end

  defp fail_migration!(message) do
    Logger.error("Verification key migration failed: #{message}")
    raise Ecto.MigrationError, message
  end
end
