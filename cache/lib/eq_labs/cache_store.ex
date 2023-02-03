defmodule EqLabs.Cache.Store do
  use Agent

  require Logger

  @table_name :eq_labs_cache
  @default_ttl 10

  def start_link(initial_state \\ %{}) do
    state = Map.merge(initial_state, %{
      table: :ets.new(@table_name, [:named_table, :public])
    })

    Agent.start_link(fn -> state end, name: __MODULE__)
  end

#  # Get the result of a function from the storage
#  def get(function) do
#    Logger.debug("Getting #{inspect(function)}")
#
#    case :ets.lookup(@table_name, function) do
#      [] -> nil
#      res -> Keyword.get(res, function)
#    end
#  end

  @doc """
  Retrieve a cached value or apply the given function caching and returning
  the result.
  """
  def get(mod, fun, args, opts \\ []) do
    get([mod, fun, args], opts)
  end

  def get(key, opts \\ []) do
#    case lookup(key) do
#      nil ->
#        ttl = Keyword.get(opts, :ttl, @default_ttl)
#        cache_apply(key, [], ttl)
#
#      result ->
#        result
#    end

    lookup(key)
  end

  # Store the result of a function in the storage
  def put(function, result, opts \\ []) do
    Logger.debug("Putting #{inspect(function)} = #{inspect(result)}, opts: #{inspect(opts)}")

    ttl = Keyword.get(opts, :ttl, @default_ttl)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(@table_name, {function, result, expiration})
  end

  def to_map() do
    # TODO: We should check freshness and discard expired ones
    :ets.foldl(
      fn {key, result, expiration}, acc ->
        case check_freshness({key, result, expiration}) do
          nil -> acc
          _ -> Map.put(acc, key, result)
        end
      end,
      %{},
      @table_name
    )
  end

  @doc """
  Lookup a cached result and check the freshness
  """
  def lookup(mod, fun, args) do
    lookup([mod, fun, args])
  end

  def lookup(key) do
    case :ets.lookup(@table_name, key) do
      [result | _] -> check_freshness(result)
      {key, result, ttl} -> check_freshness({key, result, ttl})
      [] -> nil
    end
  end

  @doc """
  Compare the result expiration against the current system time.
  """
  def check_freshness({_key, result, expiration}) do
    cond do
      expiration > :os.system_time(:seconds) -> result
      :else -> nil
    end
  end

  @doc """
  Apply the function, calculate expiration, and cache the result.
  """
  def cache_apply(mod, fun, args, ttl) do
    result = apply(mod, fun, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(@table_name, {[mod, fun, args], result, expiration})
    result
  end

  def cache_apply(key, args, ttl) do
    result = apply(key, args)
    expiration = :os.system_time(:seconds) + ttl
    :ets.insert(@table_name, {key, result, expiration})
    result
  end
end