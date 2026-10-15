defmodule Excloud.Repo.Migrations.CreateUsers do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:users) do
      add :login, :string, null: false
      add :hashed_password, :string, null: false
      add :external_id, :uuid, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:users, [:login])
    create unique_index(:users, [:external_id])

    uuid_v7_check = """
    substring(external_id::text from 15 for 1) = '7' AND
    substring(external_id::text from 20 for 1) IN ('8', '9', 'a', 'b')
    """

    create constraint(:users, :users_external_id_uuid_v7, check: uuid_v7_check)
  end
end
