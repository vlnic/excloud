defmodule Excloud.Types.EncryptedStringTest do
  @moduledoc false

  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Excloud.Types.EncryptedString
  alias ExcloudWeb.Endpoint

  @moduletag :capture_log

  test "casts strings as plaintext and rejects other values" do
    assert {:ok, "secret"} = Ecto.Type.cast(EncryptedString, "secret")

    for value <- [123, true, :secret, ~c"secret", [], %{}] do
      assert :error = Ecto.Type.cast(EncryptedString, value)
      assert :error = EncryptedString.dump(value)
      assert :error = EncryptedString.load(value)
    end
  end

  test "preserves nil through the Ecto callbacks" do
    assert {:ok, nil} = Ecto.Type.cast(EncryptedString, nil)
    assert {:ok, nil} = Ecto.Type.dump(EncryptedString, nil)
    assert {:ok, nil} = Ecto.Type.load(EncryptedString, nil)
    assert {:ok, nil} = EncryptedString.cast(nil)
    assert {:ok, nil} = EncryptedString.dump(nil)
    assert {:ok, nil} = EncryptedString.load(nil)
  end

  test "encrypts and decrypts empty, Unicode, and large strings" do
    for plaintext <- ["", "secret", "Привет, мир 🔐", String.duplicate("large secret ", 10_000)] do
      assert {:ok, encoded} = Ecto.Type.dump(EncryptedString, plaintext)
      assert encoded != plaintext
      assert {:ok, ^plaintext} = Ecto.Type.load(EncryptedString, encoded)
    end
  end

  test "packs the nonce and authenticated box in standard Base64" do
    plaintext = "secret payload"
    assert {:ok, encoded} = EncryptedString.dump(plaintext)
    assert {:ok, <<nonce::binary-size(24), box::binary>>} = Base.decode64(encoded)
    assert byte_size(box) == byte_size(plaintext) + 16

    key =
      :crypto.pbkdf2_hmac(
        :sha256,
        Endpoint.config(:secret_key_base),
        "excloud:encrypted_string:secretbox:v1",
        1000,
        32
      )

    assert {:ok, ^plaintext} = :enacl.secretbox_open(box, nonce, key)
  end

  test "loads a box created directly with enacl" do
    key =
      :crypto.pbkdf2_hmac(
        :sha256,
        Endpoint.config(:secret_key_base),
        "excloud:encrypted_string:secretbox:v1",
        1000,
        32
      )

    nonce = <<0::192>>
    box = :enacl.secretbox("external secret", nonce, key)
    encoded = Base.encode64(nonce <> box)

    assert {:ok, "external secret"} = EncryptedString.load(encoded)
  end

  test "generates a fresh nonce for each encryption of the same plaintext" do
    assert {:ok, first} = EncryptedString.dump("same secret")
    assert {:ok, second} = EncryptedString.dump("same secret")
    <<first_nonce::binary-size(24), _box::binary>> = Base.decode64!(first)
    <<second_nonce::binary-size(24), _box::binary>> = Base.decode64!(second)

    refute first_nonce == second_nonce
    assert {:ok, "same secret"} = EncryptedString.load(first)
    assert {:ok, "same secret"} = EncryptedString.load(second)
  end

  test "rejects invalid Base64 and unencrypted strings" do
    for value <- ["not base64!", "unencrypted secret", "====", <<255>>] do
      assert :error = EncryptedString.load(value)
    end
  end

  test "rejects payloads without a complete nonce and authentication tag" do
    for length <- 0..39 do
      encoded = Base.encode64(:binary.copy(<<0>>, length))
      assert :error = EncryptedString.load(encoded)
    end
  end

  test "rejects modified nonces, authentication tags, and ciphertext" do
    assert {:ok, encoded} = EncryptedString.dump("secret payload")
    decoded = Base.decode64!(encoded)

    for offset <- [0, 23, 24, 39, byte_size(decoded) - 1] do
      <<prefix::binary-size(offset), byte, suffix::binary>> = decoded
      tampered = Base.encode64(prefix <> <<Bitwise.bxor(byte, 1)>> <> suffix)
      assert :error = EncryptedString.load(tampered)
    end
  end

  test "rejects boxes encrypted with a different key" do
    nonce = :enacl.randombytes(:enacl.secretbox_NONCEBYTES())
    wrong_key = :enacl.randombytes(:enacl.secretbox_KEYBYTES())
    box = :enacl.secretbox("secret", nonce, wrong_key)

    assert :error = EncryptedString.load(Base.encode64(nonce <> box))
  end

  test "rejects truncated and extended ciphertext" do
    assert {:ok, encoded} = EncryptedString.dump("secret payload")
    decoded = Base.decode64!(encoded)
    truncated = binary_part(decoded, 0, byte_size(decoded) - 1)

    assert :error = EncryptedString.load(Base.encode64(truncated))
    assert :error = EncryptedString.load(Base.encode64(decoded <> <<0>>))
  end

  test "encrypts embedded values instead of serializing plaintext" do
    assert {:ok, encoded} = Ecto.Type.embedded_dump(EncryptedString, "secret", :json)
    assert {:ok, _bytes} = Base.decode64(encoded)
    refute encoded == "secret"
    assert {:ok, "secret"} = Ecto.Type.embedded_load(EncryptedString, encoded, :json)
  end

  test "logs the reason for invalid Base64 and incomplete payloads" do
    invalid_values = [
      {"private invalid base64!", :invalid_base64},
      {Base.encode64("private short nonce"), :incomplete_nonce},
      {Base.encode64(<<0::192, 1, 2>>), :insufficient_mac_bytes}
    ]

    for {value, reason} <- invalid_values do
      log = capture_log(fn -> assert :error = EncryptedString.load(value) end)

      assert log =~ "[error]"
      assert log =~ "EncryptedString load failed: #{reason}"
      refute log =~ value
      refute log =~ "private"
    end
  end

  test "logs failed authentication without exposing encrypted values or secrets" do
    plaintext = "private verification key"
    nonce = :enacl.randombytes(:enacl.secretbox_NONCEBYTES())
    wrong_key = :enacl.randombytes(:enacl.secretbox_KEYBYTES())
    box = :enacl.secretbox(plaintext, nonce, wrong_key)
    encoded = Base.encode64(nonce <> box)

    log = capture_log(fn -> assert :error = EncryptedString.load(encoded) end)

    assert log =~ "EncryptedString load failed: failed_verification"
    refute log =~ plaintext
    refute log =~ encoded
    refute log =~ Endpoint.config(:secret_key_base)
    refute log =~ Base.encode64(wrong_key)
  end

  test "logs invalid callback input types without logging the input" do
    value = %{secret: "private invalid value"}

    for operation <- [:cast, :dump, :load] do
      log =
        capture_log(fn ->
          assert :error = apply(EncryptedString, operation, [value])
        end)

      assert log =~ "EncryptedString #{operation} failed: invalid_type"
      refute log =~ value.secret
    end
  end

  test "does not log successful operations" do
    log =
      capture_log(fn ->
        assert {:ok, "private value"} = EncryptedString.cast("private value")
        assert {:ok, encoded} = EncryptedString.dump("private value")
        assert {:ok, "private value"} = EncryptedString.load(encoded)
        assert {:ok, nil} = EncryptedString.load(nil)
      end)

    assert log == ""
  end
end
