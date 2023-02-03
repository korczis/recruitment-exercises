defmodule EqLabs.Application do
  @moduledoc """
  The EqLabsCache.Application module.
  """

  use Application

  require Logger

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Registry, name: EqLabs.FunctionRegistry, keys: :unique},
      # {Registry, name: EqLabs.TaskRegistry, keys: :unique},
      {EqLabs.TaskScheduler, name: EqLabs.TaskScheduler},

      {EqLabs.Cache, name: EqLabs.Cache},
      {EqLabs.Cache.Store, %{}}
    ]

    Logger.debug("Starting children: #{inspect(children, pretty: true)}")

    opts = [strategy: :one_for_one, name: EqLabs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end