defmodule DataTable.LiveComponent.Filters do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    embeds_many :filters, Filter, on_replace: :delete do
      field :field, :string
      field :op, :string
      field :value, :string
    end
  end

  def changeset(data, filter_columns, attrs) do
    data
    |> cast(attrs, [])
    |> cast_embed(
      :filters,
      with: &filter_changeset(&1, filter_columns, &2),
      sort_param: :filters_sort,
      drop_param: :filters_drop
    )
  end

  def filter_changeset(data, filter_columns, attrs) do
    data
    |> cast(attrs, [:field, :op, :value])
    |> validate_required([:field, :op])
    |> validate_inclusion(:field, Map.keys(filter_columns))
    |> map_valid(fn c ->
      field = fetch_field!(c, :field)
      col_opts = Map.fetch!(filter_columns, field)
      validate_inclusion(c, :op, col_opts.ops_order)
    end)
    |> map_valid(fn c ->
      field = fetch_field!(c, :field)
      op = fetch_field!(c, :op)
      value = fetch_field!(c, :value)

      op_opts = Map.fetch!(filter_columns, field)
      case op_opts.validate.(op, value) do
        true ->
          c

        false ->
          Ecto.Changeset.add_error(c, :value, "is not valid")
      end
    end)
  end

  def map_valid(changeset, mapper) do
    case changeset.valid? do
      true -> mapper.(changeset)
      false -> changeset
    end
  end

end
