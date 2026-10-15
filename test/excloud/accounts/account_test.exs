defmodule Excloud.Accounts.AccountTest do
  @moduledoc false

  use Excloud.DataCase, async: true

  alias Excloud.Accounts.Account

  test "persists a shared account without an owner and loads its type as an atom" do
    assert {:ok, account} =
      %Account{}
      |> Account.changeset(%{type: :member})
      |> Repo.insert()

    reloaded = Repo.get!(Account, account.id)

    assert is_integer(reloaded.id)
    assert reloaded.type == :member
    refute Map.has_key?(reloaded, :user_id)
    assert %DateTime{} = reloaded.inserted_at
    assert %DateTime{} = reloaded.updated_at

    assert %{rows: [["member"]]} =
      Ecto.Adapters.SQL.query!(Repo, "SELECT type FROM accounts WHERE id = $1", [account.id])

    assert Repo.get_by!(Account, type: :member).id == account.id
  end

  test "accepts an existing atom name from string attributes" do
    assert {:ok, account} =
      %Account{}
      |> Account.changeset(%{"type" => Atom.to_string(:member)})
      |> Repo.insert()

    assert Repo.get!(Account, account.id).type == :member
  end

  test "requires a type" do
    changeset = Account.changeset(%Account{}, %{})

    assert errors_on(changeset) == %{type: ["can't be blank"]}
  end

  test "rejects invalid types" do
    for type <- [123, [], %{}] do
      changeset = Account.changeset(%Account{}, %{type: type})
      assert "is invalid" in errors_on(changeset).type
    end
  end

  test "rejects unknown strings without creating atoms" do
    type = "unknown_account_type_#{System.unique_integer([:positive])}"
    assert_raise ArgumentError, fn -> String.to_existing_atom(type) end

    changeset = Account.changeset(%Account{}, %{type: type})

    assert "is invalid" in errors_on(changeset).type
    assert_raise ArgumentError, fn -> String.to_existing_atom(type) end
  end

  test "keeps one shared account per type" do
    %Account{} |> Account.changeset(%{type: :member}) |> Repo.insert!()

    assert {:error, changeset} =
      %Account{}
      |> Account.changeset(%{type: :member})
      |> Repo.insert()

    assert "has already been taken" in errors_on(changeset).type
  end

  test "does not accept an owner from attributes" do
    assert {:ok, account} =
      %Account{}
      |> Account.changeset(%{type: :member, user_id: 123})
      |> Repo.insert()

    assert account.type == :member
    refute Map.has_key?(account, :user_id)
  end

  test "updates the account type" do
    account =
      %Account{}
      |> Account.changeset(%{type: :member})
      |> Repo.insert!()

    assert {:ok, updated} = account |> Account.changeset(%{type: :other}) |> Repo.update()

    assert updated.id == account.id
    assert Repo.get!(Account, account.id).type == :other
  end
end
