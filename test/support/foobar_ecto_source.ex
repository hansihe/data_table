defmodule FoobarEctoSource do
  use DataTable.Ecto

  import Ecto.Query

  defmodule TestSchema do
    use Ecto.Schema

    schema "test" do
    end
  end

  ecto_source do

    query fn ->
      from(
        s in TestSchema,
        as: :manual_capture
      )
    end

    fields [manual_capture: s] do
      field :id, s.id, filter: :integer
    end

    query_fragment :creator do
      query &join(
        &1, :inner, [manual_capture: s],
        u in Model.User,
        as: :creator,
        on: s.creator_id == u.id
      )

      fields [creator: u] do
        field :creator_name, u.name
      end
    end

    execute fn query ->
      {:executed, query}
    end

  end

end
