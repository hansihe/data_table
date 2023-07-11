defmodule DataTable.Filters do
  use Ecto.Schema

  embedded_schema do
    embeds_many :filters, Filter, on_replace: :delete do
      field :field, :string
      field :op, :string
      field :value, :string
    end
  end
end
