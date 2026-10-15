defmodule Excloud.Repo.Migrations.MakeAccountsShared do
  @moduledoc false

  use Ecto.Migration

  def up do
    execute "LOCK TABLE users, accounts IN ACCESS EXCLUSIVE MODE"

    execute """
    DO $$
    BEGIN
      IF EXISTS (
        SELECT user_id FROM accounts
        GROUP BY user_id HAVING COUNT(DISTINCT type) > 1
      ) THEN
        RAISE EXCEPTION 'Cannot choose one account for users with multiple account types';
      END IF;

      IF EXISTS (
        SELECT 1 FROM users
        WHERE NOT EXISTS (SELECT 1 FROM accounts WHERE accounts.user_id = users.id)
      ) THEN
        RAISE EXCEPTION 'Assign an account to every existing user before migrating';
      END IF;
    END
    $$;
    """

    alter table(:users) do
      add :account_id, references(:accounts)
    end

    execute """
    UPDATE users
    SET account_id = assignments.account_id
    FROM (
      SELECT owned.user_id, MIN(shared.id) AS account_id
      FROM accounts AS owned
      JOIN accounts AS shared ON shared.type = owned.type
      GROUP BY owned.user_id
    ) AS assignments
    WHERE users.id = assignments.user_id
    """

    execute """
    DELETE FROM accounts
    WHERE id NOT IN (SELECT MIN(id) FROM accounts GROUP BY type)
    """

    alter table(:users) do
      modify :account_id, :bigint, null: false
    end

    drop index(:accounts, [:user_id])

    alter table(:accounts) do
      remove :user_id
    end

    create index(:users, [:account_id])
    create unique_index(:accounts, [:type])
  end

  def down do
    raise Ecto.MigrationError, "Cannot restore shared accounts to individual owners automatically"
  end
end
