defmodule DataTable.Ecto.Dsl.Transformers.MakeFieldDynamic do
  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer
  alias DataTable.Ecto.Dsl

  alias Ecto.Query.Builder

  require Ecto.Query

  def transform(dsl_state) do
    fields =
      dsl_state
      |> Transformer.get_entities([:ecto_source])
      |> Enum.reduce(%{}, fn
        %Dsl.Fields{} = fields, acc ->
          handle_fields(nil, fields, acc)

        %Dsl.QueryFragment{name: frag_name, fields: fields}, acc ->
          Enum.reduce(fields, acc, fn
            %Dsl.Fields{} = fields, acc ->
              handle_fields(frag_name, fields, acc)

            _, acc ->
              acc
          end)

        _, acc ->
          acc
      end)

    dsl_state = Transformer.persist(dsl_state, :ecto_source_fields, fields)

    {:ok, dsl_state}
  end

  defp handle_fields(fragment, %Dsl.Fields{binds: binds, fields: fields}, field_map) do
    Enum.reduce(fields, field_map, fn %Dsl.Field{name: name, expr: expr, filter: filter}, field_map ->
      data = %{
        fragment: fragment,
        name: name,
        binds: binds,
        expr: expr,
        filter: filter
      }
      Map.put(field_map, name, data)
    end)
  end

end
