defmodule EqLabs do
  defmacro __using__(_opts \\ []) do
    quote do
      alias EqLabs.Cache
      alias EqLabs.Cache.Store
      alias EqLabs.FunctionRegistry
      alias EqLabs.PubSub
      alias EqLabs.TaskExecutor
      alias EqLabs.TaskRegistry
      alias EqLabs.TaskScheduler
      alias EqLabs.WeatherData
    end
  end
end