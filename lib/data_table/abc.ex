defmodule Abc do
  use DataTable.Ecto

  import Ecto.Query

  ecto_source do

    query fn ->
      from(
        s in Model.ManualCapture,
        as: :manual_capture
      )
    end

    fields [manual_capture: s] do
      field :id, s.id
      field :creator_id, s.creator_id
      field :store_id, s.store_id
      field :object_id, s.object_id
    end

    query_fragment :stored_object do
      query &join(
        &1, :inner, [manual_capture: s],
        o in Model.StoredObject,
        as: :stored_object,
        on: s.stored_object == o.id
      )

      fields [stored_object: o] do
        field :object_sha256_hash, o.sha256_hash
        field :object_path, o.path
      end
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

    query_fragment :store do
      query &join(
        &1, :left, [manual_capture: s],
        st in Model.Store,
        as: :store,
        on: s.store_id == st.id
      )

      fields [store: st] do
        field :store_name, st.nickname
      end
    end

    execute fn query ->
      {:executed, query}
    end

  end
end
