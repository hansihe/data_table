defmodule Example.Model.Article do
  use Ecto.Schema

  schema "articles" do
    field :title, :string
    field :body, :string
  end
end
