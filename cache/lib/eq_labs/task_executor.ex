defmodule EqLabs.TaskExecutor do
  @moduledoc """
    This module provides functionality to execute a function and store its result in the cache.

    ## Example

    ```elixir
      iex> EqLabs.TaskExecutor.execute("function_name")
      {:error, :not_registered}
    ```
  """

  alias EqLabs.Cache.Store
  alias EqLabs.FunctionRegistry

  require Logger

  # Execute a function and store its result in the cache
#  @type ttl :: integer
#  @type function :: map(fun: (() -> {:ok, term} | term), ttl: ttl)
#  @spec execute(term()) :: {:error, :not_registered} | {:ok, tuple}
  def execute(name) do
    case FunctionRegistry.get(name) do
      nil ->
        Logger.error("Function not registered #{inspect(name)}")
        {:error, :not_registered}
      {_pid, %{fun: fun, ttl: ttl} = function} ->
        Logger.debug("Executing #{inspect(name)} -> #{inspect(function)}")
        case fun.() do
          {:ok, res} ->
            # TODO: Set ttl
            true = Store.put(name, res, ttl: ttl)
            {name, {:ok, res}}
          other -> other
        end
    end
  end
end
