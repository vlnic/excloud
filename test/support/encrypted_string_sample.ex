defmodule Excloud.EncryptedStringSample do
  @moduledoc false

  use Ecto.Schema

  schema "encrypted_string_samples" do
    field :value, Excloud.Types.EncryptedString, redact: true
  end
end
