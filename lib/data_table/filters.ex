defmodule DataTable.Filters do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    embeds_many :filters, Filter, on_replace: :delete do
      field :field, :string
      field :op, :string
      field :value, :string
    end
  end

  def changeset2(data, attrs) do
    data
    |> cast(attrs, [])
    |> cast_embed(
      :filters,
      with: &filter_changeset2(&1, &2),
      sort_param: :filters_sort,
      drop_param: :filters_drop
    )
  end

  def filter_changeset2(data, attrs) do
    data
    |> cast(attrs, [:field, :op, :value])
  end

  def changeset(data, spec, attrs) do
    data
    |> cast(attrs, [])
    |> cast_embed(:filters,
      with: &filter_changeset(&1, spec, &2),
      sort_param: :filters_sort,
      drop_param: :filters_drop
    )
  end

  def filter_changeset(data, spec, attrs) do
    data
    |> cast(attrs, [:field, :op, :value])
    |> validate_required([:field, :op])
    |> validate_inclusion(:field, Enum.map(spec.filterable_columns, &Atom.to_string(&1.col_id)))
    |> map_valid(fn c ->
      field = fetch_field!(c, :field)
      atom_field = String.to_existing_atom(field)
      filter_data = Enum.find(spec.filterable_columns, & &1.col_id == atom_field)
      type_map = spec.filter_types[filter_data.type]
      ops = type_map.ops
      values = Enum.map(ops, fn {id, _} -> Atom.to_string(id) end)
      validate_inclusion(c, :op, values)
    end)
    |> map_valid(fn c ->
      field = fetch_field!(c, :field)
      atom_field = String.to_existing_atom(field)
      filter_data = Enum.find(spec.filterable_columns, & &1.col_id == atom_field)
      value = fetch_field!(c, :value)

      case validate_value(value, filter_data.type) do
        :ok -> c
        {:error, reason} -> add_error(c, :value, reason)
      end
    end)
  end

  def validate_value(nil, :integer) do
    {:error, "must be a valid number"}
  end
  def validate_value(value, :integer) do
    case Integer.parse(value) do
      {_val, ""} -> :ok
      _ -> {:ok, "must be a valid number"}
    end
  end
  def validate_value(_value, _type) do
    :ok
  end

  def map_valid(changeset, mapper) do
    case changeset.valid? do
      true -> mapper.(changeset)
      false -> changeset
    end
  end

end
