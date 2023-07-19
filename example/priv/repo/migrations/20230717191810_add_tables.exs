defmodule Example.Repo.Migrations.AddTables do
  use Ecto.Migration

  def up do
    create table("articles") do
      add :title, :text
      add :body, :text
    end
  end
end
