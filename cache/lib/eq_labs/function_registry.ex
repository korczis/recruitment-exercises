defmodule EqLabs.FunctionRegistry do
  @moduledoc """
    The `FunctionRegistry` module is used to store and manage functions.

    Functions can be registered with the module, and then looked up and retrieved later by key.
    The functions can also be scheduled with a specified TTL (time-to-live) and refresh interval.


    A module to register functions with the ability to refresh them and
    automatically schedule them for execution.

    # Examples

    ## Registering a function

    ```elixir

      iex> EqLabs.FunctionRegistry.register("my_fun", &(&1 + &2), ttl: 3600, refresh_interval: 600)
      {:ok, #PID<0.127.0>}

    ```

    ## Looking up a registered function

    ```elixir

      iex> EqLabs.FunctionRegistry.lookup("my_fun")
      %{
        fun: &(&1 + &2),
        key: "my_fun",
        refresh_interval: 600,
        ttl: 3600
      }

    ```

    ## Getting all registered functions

    ```elixir

      iex> EqLabs.FunctionRegistry.get_all()
      %{"my_fun" => [%{
        fun: &(&1 + &2),
        key: "my_fun",
        refresh_interval: 600,
        ttl: 3600
      }]}

   ```
  """

  require Registry

  @registry __MODULE__

  alias EqLabs.TaskScheduler

  require Logger

  @doc """
    Registers a function with the given `key`, `fun`, and `opts` options.
    The function `fun` must be of arity 0.

    ## Examples

    ```elixir

      iex> fun = fn -> :hello end
      #Function<6.52032458/0 in :erl_eval.expr/5>

      iex> opts = [ttl: 3600, refresh_interval: 300]
      [ttl: 3600, refresh_interval: 300]

      iex> EqLabs.FunctionRegistry.register(:my_function, fun, opts)
      {:ok, #PID<0.168.0>}

    ```

    ### Another example

    ```elixir

      iex> EqLabs.FunctionRegistry.register("my_fun", &(&1 + &2), ttl: 3600, refresh_interval: 600)
      {:ok, #PID<0.127.0>}
    ```
  """
  def register(key, fun, opts) do
    Logger.debug("Registering function key: #{key}, fun: #{inspect(fun, pretty: true)}, opts: #{inspect(opts)}")

    opts = Keyword.merge(TaskScheduler.default_schedule_opts(), opts)

    function = %{
      fun: fun,
      key: key,
      ttl: Keyword.get(opts, :ttl),
      refresh_interval: Keyword.get(opts, :refresh_interval)
    }

    register(key, function)
  end

  def register(key, function) do
    Logger.debug("Registering function key: #{key}, fun: #{inspect(function, pretty: true)}")

    case Registry.register(@registry, key, function) do
      {:ok, pid} ->
        opts = [
          ttl: function[:ttl],
          refresh_interval: function[:refresh_interval],
        ]
        # :ok = TaskScheduler.schedule(key, opts)
        {:ok, pid}
      {:error, {:already_registered, _pid} = res} ->
        res
    end
  end

  @doc """
     Looks up a registered function by key.

     ## Examples

    ```elixir
    iex> fun = fn -> :hello end
    #Function<6.52032458/0 in :erl_eval.expr/5>

    iex> EqLabs.FunctionRegistry.register(:my_function, fun, [ttl: 3600, refresh_interval: 300])
    {:ok, #PID<0.168.0>}

    iex> EqLabs.FunctionRegistry.lookup(:my_function)
    {#PID<0.290.0>,
    %{
     fun: #Function<43.3316493/0 in :erl_eval.expr/6>,
     key: :my_function,
     refresh_interval: 3000,
     ttl: 60000
    }}
    ```
  """
  def lookup(key) do
    Logger.debug("Looking up for function #{inspect(key)}")

    case Registry.lookup(@registry, key) do
      [res] -> res
      [] -> nil
      other -> other
    end
  end

  def get(key), do: lookup(key)

  def get_all() do
    @registry
    |>Registry.select([{{:"$1", :_, :_}, [], [:"$1"]}])
    |> Enum.reduce(%{}, fn key, acc ->
      Map.put(acc, key, get(key))
    end)
  end

  def all(), do: get_all()
end
