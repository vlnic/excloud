defmodule Excloud.Types.EncryptedString do
  @moduledoc """
  Encrypts strings with enacl Secret Box when writing them through Ecto.

  The database representation is `Base.encode64(nonce <> box)`, where `box`
  contains the authentication tag and ciphertext. Every dump generates a fresh
  24-byte nonce. Loading verifies the box before returning the plaintext.
  Errors are logged without plaintext, encrypted values, or key material.

  The 32-byte key is derived at runtime from
  `ExcloudWeb.Endpoint.config(:secret_key_base)` using PBKDF2-HMAC-SHA256 with
  1,000 iterations and the salt `excloud:encrypted_string:secretbox:v1`.
  Existing values require the same secret key base and derivation parameters.

  Use `field :secret, Excloud.Types.EncryptedString, redact: true` in schemas.
  Use a database `:text` column for unrestricted string lengths, as the nonce,
  authentication tag, and Base64 encoding increase the stored size.
  """

  use Ecto.Type

  alias ExcloudWeb.Endpoint
  alias Plug.Crypto.KeyGenerator

  require Logger

  @key_salt "excloud:encrypted_string:secretbox:v1"
  @mac_bytes 16

  @impl true
  def type, do: :string

  @impl true
  def cast(nil), do: {:ok, nil}
  def cast(value) when is_binary(value), do: {:ok, value}
  def cast(_value), do: log_error(:cast, :invalid_type)

  @impl true
  def dump(nil), do: {:ok, nil}

  def dump(value) when is_binary(value) do
    nonce = :enacl.randombytes(:enacl.secretbox_NONCEBYTES())
    box = :enacl.secretbox(value, nonce, key!())
    {:ok, Base.encode64(nonce <> box)}
  end

  def dump(_value), do: log_error(:dump, :invalid_type)

  @impl true
  def load(nil), do: {:ok, nil}

  def load(value) when is_binary(value) do
    with {:ok, decoded} <- decode_base64(value),
    {:ok, nonce, box} <- unpack_box(decoded),
    :ok <- ensure_byte_size_at_least_mac_bytes(box),
    {:ok, plaintext} <- :enacl.secretbox_open(box, nonce, key!()) do
      {:ok, plaintext}
    else
      {:error, reason} -> log_error(:load, reason)
    end
  end

  def load(_value), do: log_error(:load, :invalid_type)

  @impl true
  def embed_as(_format), do: :dump

  defp decode_base64(value) do
    case Base.decode64(value) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, :invalid_base64}
    end
  end

  defp unpack_box(decoded) do
    nonce_bytes = :enacl.secretbox_NONCEBYTES()

    case decoded do
      <<nonce::binary-size(nonce_bytes), box::binary>> -> {:ok, nonce, box}
      _incomplete -> {:error, :incomplete_nonce}
    end
  end

  defp ensure_byte_size_at_least_mac_bytes(box) when byte_size(box) >= @mac_bytes, do: :ok
  defp ensure_byte_size_at_least_mac_bytes(_box), do: {:error, :insufficient_mac_bytes}

  defp key! do
    case Endpoint.config(:secret_key_base) do
      secret when is_binary(secret) and byte_size(secret) > 0 ->
        KeyGenerator.generate(secret, @key_salt,
          iterations: 1000,
          length: :enacl.secretbox_KEYBYTES(),
          digest: :sha256,
          cache: Plug.Crypto.Keys
        )

      _missing_or_invalid ->
        log_error(:key_derivation, :invalid_secret_key_base)
        raise ArgumentError, "ExcloudWeb.Endpoint.secret_key_base must be a non-empty string"
    end
  end

  defp log_error(operation, reason) do
    Logger.error("EncryptedString #{operation} failed: #{reason}")
    :error
  end
end
