defmodule HexWeb.PackageTest do
  use HexWeb.ModelCase

  alias HexWeb.User
  alias HexWeb.Package

  setup do
    User.build(%{username: "eric", email: "eric@mail.com", password: "eric"}, true) |> HexWeb.Repo.insert!
    :ok
  end

  test "create package and get" do
    user = HexWeb.Repo.get_by!(User, username: "eric")
    user_id = user.id

    Package.build(user, pkg_meta(%{name: "ecto", description: "DSL"})) |> HexWeb.Repo.insert!
    assert [%User{id: ^user_id}] = HexWeb.Repo.get_by(Package, name: "ecto") |> assoc(:owners) |> HexWeb.Repo.all
    assert is_nil(HexWeb.Repo.get_by(Package, name: "postgrex"))
  end

  test "update package" do
    user = HexWeb.Repo.get_by!(User, username: "eric")
    package = Package.build(user, pkg_meta(%{name: "ecto", description: "DSL"})) |> HexWeb.Repo.insert!

    Package.update(package, %{"meta" => %{"maintainers" => ["eric", "josé"], "description" => "description", "licenses" => ["Apache"]}})
    |> HexWeb.Repo.update!
    package = HexWeb.Repo.get_by(Package, name: "ecto")
    assert length(package.meta.maintainers) == 2
  end

  test "validate blank description in metadata" do
    meta = %{
      "maintainers" => ["eric", "josé"],
      "licenses"     => ["apache", "BSD"],
      "links"        => %{"github" => "www", "docs" => "www"},
      "description"  => ""}

    user = HexWeb.Repo.get_by!(User, username: "eric")
    assert {:error, changeset} = Package.build(user, pkg_meta(%{name: "ecto", meta: meta})) |> HexWeb.Repo.insert
    assert changeset.errors == []
    assert changeset.changes.meta.errors == [description: {"can't be blank", []}]
  end

  test "packages are unique" do
    user = HexWeb.Repo.get_by!(User, username: "eric")
    Package.build(user, pkg_meta(%{name: "ecto", description: "DSL"})) |> HexWeb.Repo.insert!
    assert {:error, _} = Package.build(user, pkg_meta(%{name: "ecto", description: "Domain-specific language"})) |> HexWeb.Repo.insert
  end

  test "reserved names" do
    user = HexWeb.Repo.get_by!(User, username: "eric")
    assert {:error, %{errors: [name: {"is reserved", []}]}} = Package.build(user, pkg_meta(%{name: "elixir", description: "Awesomeness."})) |> HexWeb.Repo.insert
  end
end
