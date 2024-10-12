defmodule DataTable.Source do
  alias __MODULE__.{Query, Result}

  @type source_module :: module()
  @type source_opts :: any()

  @callback query({source :: source_module(), opts :: source_opts()}, query :: Query.t()) :: Result.t()
  @callback filterable_fields({source :: source_module(), opts :: source_opts()}) :: any()
  @callback filter_types({source :: source_module(), opts :: source_opts()}) :: any()
  @callback key({source :: source_module(), opts :: source_opts()}) :: atom()

  def query({mod, opts}, query_params) do
    mod.query(opts, query_params)
  end

  def filterable_fields({mod, opts}) do
    mod.filterable_fields(opts)
  end

  def filter_types({mod, opts}) do
    mod.filter_types(opts)
  end

  def key({mod, opts}) do
    mod.key(opts)
  end

end
