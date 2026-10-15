defmodule Excloud.Types.EncryptedStringPersistenceTest do
  @moduledoc false

  use Excloud.DataCase, async: true

  alias Excloud.EncryptedStringSample
  alias Excloud.Types.EncryptedString

  setup do
    Repo.query!("""
    CREATE TEMP TABLE encrypted_string_samples (
      id bigserial PRIMARY KEY,
      value text
    ) ON COMMIT DROP
    """)

    :ok
  end

  test "stores ciphertext and transparently reloads plaintext" do
    plaintext = String.duplicate("confidential value ", 100)
    sample = Repo.insert!(%EncryptedStringSample{value: plaintext})

    assert %{rows: [[stored]]} =
      Repo.query!("SELECT value FROM encrypted_string_samples WHERE id = $1", [sample.id])

    refute stored == plaintext
    assert {:ok, ^plaintext} = EncryptedString.load(stored)
    assert Repo.get!(EncryptedStringSample, sample.id).value == plaintext
    refute inspect(sample) =~ plaintext
  end

  test "encrypts updated values and leaves null values as null" do
    sample = Repo.insert!(%EncryptedStringSample{})
    assert Repo.get!(EncryptedStringSample, sample.id).value == nil

    assert {:ok, updated} = sample |> change(value: "updated secret") |> Repo.update()

    assert %{rows: [[stored]]} =
      Repo.query!("SELECT value FROM encrypted_string_samples WHERE id = $1", [updated.id])

    refute stored == "updated secret"
    assert Repo.get!(EncryptedStringSample, updated.id).value == "updated secret"
  end
end
