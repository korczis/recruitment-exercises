defmodule EqLabs.Cache do
  @moduledoc """
  This module implements a cache store using `GenServer` to store values and
  functions that can be registered and later retrieved.

  The module provides an API for registering functions that return either `{:ok, any()}`
  or `{:error, any()}`. The cache store updates the value for each function in a worker process
  every `refresh_interval` seconds, and sets a `ttl` for how long the value can be cached.

    Module: Cache
      - store the functions and their results
      - schedule the execution of functions at given intervals
      - update the cache with the results of the functions

  Module: Cache.Storage
      - store the results of the functions
      - provide fast access to the data

  Module: FunctionRegistry
      - register functions with the cache
      - store the functions and their metadata (TTL and refresh interval)

    Module: TaskScheduler
      - schedule the execution of functions at given intervals
      - keep track of running tasks and their results

    Module: TaskExecutor
      - execute the functions
      - update the cache with the results of the functions

    Module: PubSub (optional)
      - allow communication between processes
      - notify interested parties of cache updates
  """

  use GenServer

  alias EqLabs.Cache.Store
  alias EqLabs.FunctionRegistry
  alias EqLabs.TaskScheduler

  require Logger

  @type result ::
          {:ok, any()}
          | {:error, :timeout}
          | {:error, :not_registered}

  @impl GenServer
  def init(init_state \\ %{}) do
    {:ok, init_state}
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{functions: %{}}, opts)
  end

  @doc ~s"""
  Get the value associated with `key`.

  Details:
    - If the value for `key` is stored in the cache, the value is returned
      immediately.
    - If a recomputation of the function is in progress, the last stored value
      is returned.
    - If the value for `key` is not stored in the cache but a computation of
      the function associated with this `key` is in progress, wait up to
      `timeout` milliseconds. If the value is computed within this interval,
      the value is returned. If the computation does not finish in this
      interval, `{:error, :timeout}` is returned.
    - If `key` is not associated with any function, return `{:error,
      :not_registered}`
  """
  @impl GenServer
  def handle_call({:get, key, timeout}, _from, state) do
    case Store.get(key) do
      nil ->
        # Value not found
        case FunctionRegistry.get(key) do
          nil ->
            {:reply, {:error, :not_registered}, state}
          {pid, f} ->
          try do
            Logger.debug("Function found pid: #{inspect(pid)}, function: #{inspect(f)}")
            result = GenServer.call(TaskScheduler, {:schedule, key, [timeout: timeout]}, timeout)
            {:reply, result, state}
          catch
            :exit, reason -> {:reply, {:error, :timeout}, state}
          end
        end
      result -> {:reply, {:ok, result}, state}
    end
  end

  @impl GenServer
  def handle_cast({:register_function, fun, key, ttl, refresh_interval}, state) do
    Logger.debug("Registering as #{inspect(key)} function #{inspect(fun)}, ttl: #{ttl}, refresh_interval: #{refresh_interval}")


    # Check if the function is already registerd
    case FunctionRegistry.get(key) do
      nil ->
        # If not, then crete object representing function + meta
        # Function registration initializes first execution
        _ = FunctionRegistry.register(key, %{
          fun: fun,
          key: key,
          ttl: ttl,
          refresh_interval: refresh_interval,
        })

        {:noreply, state}

      {_pid, function} = _other ->
        # Function worker is already running
        # _pid = spawn_link fn -> worker(function, state) end
        {:noreply, state}
    end
  end

  @spec register_function(
          fun :: (() -> {:ok, any()} | {:error, any()}),
          key :: any(),
          ttl :: non_neg_integer(),
          refresh_interval :: non_neg_integer()
        ) :: :ok | {:error, :already_registered}
  def register_function(fun, key, ttl, refresh_interval)
      when is_function(fun, 0) and is_integer(ttl) and ttl > 0 and
           is_integer(refresh_interval) and refresh_interval < ttl do

    case FunctionRegistry.get(:key) do
      nil ->
        GenServer.cast(__MODULE__, {:register_function, fun, key, ttl, refresh_interval})
      [{_pid, _}] ->
        {:error, :already_registered}
      {_pid, _} ->
        {:error, :already_registered}
    end
  end

  @spec get(any(), non_neg_integer(), Keyword.t()) :: result
  def get(key, timeout \\ 30_000, _opts \\ []) when is_integer(timeout) and timeout > 0 do
    Logger.debug("Getting cached key: #{inspect(key)}, timeout: #{inspect(timeout)}")
    GenServer.call(__MODULE__, {:get, key, timeout})
  end
end

#defimpl Inspect, for: EqLabs.Cache do
#  import Inspect.Algebra
#
#  def inspect(map_set, opts) do
#    concat(["MapSet.new(", Inspect.List.inspect(MapSet.to_list(map_set), opts), ")"])
#  end
#end
