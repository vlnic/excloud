defmodule Excloud.Repo.Migrations.CreateAccounts do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :type, :string, null: false
      add :user_id, references(:users), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:accounts, [:user_id])
  end
end
