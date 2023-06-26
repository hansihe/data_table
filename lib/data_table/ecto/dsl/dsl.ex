defmodule DataTable.Ecto.Dsl do

  @field %Spark.Dsl.Entity{
    name: :field,
    target: DataTable.Ecto.Dsl.Field,
    schema: DataTable.Ecto.Dsl.Field.opt_schema(),
    args: [:name, :expr]
  }

  @field_with_opts %Spark.Dsl.Entity{
    name: :field,
    target: DataTable.Ecto.Dsl.Field,
    schema: DataTable.Ecto.Dsl.Field.opt_schema(),
    args: [:name, :expr, :opts]
  }

  @fields %Spark.Dsl.Entity{
    name: :fields,
    target: DataTable.Ecto.Dsl.Fields,
    schema: DataTable.Ecto.Dsl.Fields.opt_schema(),
    entities: [
      fields: [
        @field
      ]
    ],
    args: [:binds]
  }

  @query_fragment %Spark.Dsl.Entity{
    name: :query_fragment,
    target: DataTable.Ecto.Dsl.QueryFragment,
    schema: DataTable.Ecto.Dsl.QueryFragment.opt_schema(),
    entities: [
      fields: [
        @fields
      ]
    ],
    args: [:name]
  }

  @ecto_source %Spark.Dsl.Section{
    name: :ecto_source,
    schema: [
      query: [
        type: {:or, [{:fun, 0}, {:fun, 1}]},
        required: true
      ],
      execute: [
        type: {:or, [{:fun, 1}, {:fun, 2}]},
        required: true
      ]
    ],
    entities: [
      @fields,
      @query_fragment
    ]
  }

  @sections [
    @ecto_source
  ]

  use Spark.Dsl.Extension,
    sections: @sections,
    transformers: [__MODULE__.Transformers.MakeFieldDynamic],
    verifiers: [__MODULE__.Verifiers.FragmentOrder]

end
