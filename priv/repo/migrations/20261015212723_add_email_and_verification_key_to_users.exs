defmodule Excloud.Repo.Migrations.AddEmailAndVerificationKeyToUsers do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:users) do
      add :email, :string
      add :verification_key, :string
    end

    create unique_index(:users, ["lower(email)"], name: :users_email_index)
  end
end
