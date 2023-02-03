defmodule EqLabs.TaskScheduler do
  @moduledoc """
  The `TaskScheduler` module is responsible for scheduling tasks to be executed at a set interval.
  """

  use GenServer

  alias EqLabs.FunctionRegistry
  alias EqLabs.TaskExecutor

  require Logger

  @default_ttl 5
  @default_refresh_interval 10

  @default_schedule_opts [
    ttl: @default_ttl,
    refresh_interval: @default_refresh_interval
  ]

  @impl GenServer
  @spec init(%{}) :: {:ok, %{}}
  def init(%{}) do
    _ = schedule_tasks(%{})
    {:ok, %{}}
  end

  @pub_sub EqLabs.TaskScheduler.PubSub

  @spec start_link(list()) :: {:ok, pid} | {:error, any}
  @doc """
  Starts the `TaskScheduler` GenServer process with the given options.

  ## Examples

    ```elixir
    EqLabs.TaskScheduler.start_link()
    ```
  """
  def start_link(init_args \\ []) do
    Logger.debug("init_args = #{inspect(init_args)}")

    {:ok, pub_sub} =
      Registry.start_link(
        keys: :duplicate,
        name: @pub_sub,
        partitions: System.schedulers_online()
      )

    GenServer.start_link(__MODULE__, %{pub_sub: pub_sub}, init_args)
  end

  def default_schedule_opts(), do: @default_schedule_opts

  @spec schedule(term(), keyword()) :: :ok
  @doc """
  Schedules a task to be executed at the given refresh_interval.

  # Examples

    EqLabs.TaskScheduler.schedule("some_task", 5_000)
  """
  def schedule(key, opts \\ @default_schedule_opts) do
    opts = Keyword.merge(default_schedule_opts(), opts)
    Logger.info("Scheduling function key: #{inspect(key)}, opts: #{inspect(opts)}")

    GenServer.cast(__MODULE__, {:schedule, key, opts})
  end

  def unschedule(key) do
    Logger.info("Un-scheduling function key: #{inspect(key)}")

    :ok = GenServer.cast(__MODULE__, {:unschedule, key,})
  end

  @impl GenServer
  def handle_call({:schedule, key, opts} = msg, _from, state) do
    Logger.debug("Handling cast #{inspect(msg)}")

    task = %Task{} = schedule_task(key)

    function =
      state
      |> Map.get(key, %{})
      |> Map.put(:task, task)

    res = case Keyword.get(opts, :timeout, false) do
      false -> task
      true -> Task.await(task)
      timeout when is_integer(timeout) -> Task.await(task, timeout)
    end

    {:reply, res,  Map.put(state, key, function)}
  end

  @impl GenServer
  @spec handle_cast({:schedule, term(), keyword()}, map()) :: {:noreply, map()}
  def handle_cast({:schedule, key, opts} = msg, state) do
    Logger.info("Schedule cast requests - #{inspect(msg)}")

    # TODO: Merge opts
    with {_pid, function} <- FunctionRegistry.get(key) do
      new_state =
        case Map.get(state, key) do
          nil ->
            task = %Task{} = schedule_task(key)
            state
            |> Map.put(key, %{
              function: function |> Map.merge(Enum.into(opts, %{})),
              task: task
            })
          f ->
            state
        end
      {:noreply, new_state}
    else
      _ -> {:noreply, state}
    end
  end

  @impl GenServer
  def handle_cast({:unschedule, key}, state) do
    # We check is something is scheduled under key specified
    new_state =
      case Map.get(state, key) do
        nil -> state
        %{
          task: %{
            pid: pid
          } = task,
          timer_ref: timer_ref
        } = function ->
          Logger.info("Shutting down - #{inspect(function)}")
          _ = Task.shutdown(task, :brutal_kill)

          # TODO: Cancel timer here
          Logger.info("Canceling timer #{inspect(timer_ref)}")
          _ = Process.cancel_timer(timer_ref)

          {_, new_state} = Map.pop(state, key)
          new_state
    end

    {:noreply, new_state}
  end

  @doc """
  Executes function and schedules next run
  """
  @impl GenServer
  def handle_info({:execute, key}, state) do
    {_key, {:ok, _res}} = TaskExecutor.execute(key)

    task = %Task{} = schedule_task(key)

    function =
      state
      |> Map.get(key, %{})
      |> Map.put(:task, task)

    new_state = Map.put(state, key, function)

    {:noreply, new_state}
  end

  def handle_info({:DOWN, ref, :process, pid, :normal}, state) do
    Logger.info("Task has finished, ref: #{inspect(ref)}, pid: #{inspect(pid)}")

    {:noreply, state}
  end

  #  @impl GenServer
  def handle_info({from, {key, {:ok, _result}} = msg}, state) do
    Logger.debug("Handling info from: #{inspect(from)}, key: #{inspect(key)} msg: #{inspect(msg)}")

    new_state =
      case Map.get(state, key) do
        %{function: function, task: task} = f ->
          # Schedule the function to run again after the refresh interval
          timer_ref = Process.send_after(__MODULE__, {:execute, key}, function.refresh_interval * 1000)

          # We store the timer in case it will be unscheduled
          new_f = Map.put(f, :timer_ref, timer_ref)

          state
          |> Map.put(key, new_f)
        other ->
          {_, new_state} = Map.pop(other, key)
          new_state
      end

    {:noreply, new_state}
  end

  defp schedule_tasks(keys) do
    Logger.debug("Scheduling tasks #{inspect(keys)}")

    keys
    |> Enum.map(fn key ->
      _task = %Task{} = schedule_task(key)
    end)
  end

  @doc """
    Here we create async task wrapping function/0 implementation
  """
  defp schedule_task(key) do
    Logger.debug("Scheduling task #{inspect(key)}")

    case FunctionRegistry.get(key) do
      {_pid, _function} ->
        task = %Task{} = run_task(key)
      nil -> {:error, :not_registered}
      other -> other
    end
  end

  def run_task(key) do
    Task.async(fn ->
      with {:ok, result} <- run_function(key) do

#        Registry.dispatch(@pub_sub, key, fn entries ->
#          for {pid, _} <- entries, do: send(pid, {key, result})
#        end)

        {key, {:ok, result}}
      else
        other -> other
      end
    end)
  end

#  def handle_info(:run, state) do
#    # Get the current state and schedule the tasks again
#    # schedule_tasks(state)
#    {:noreply, state}
#  end

  def run_function(key) do
    Logger.debug("Running function #{inspect(key)}")
    {^key, {:ok, _} = res} = TaskExecutor.execute(key)
    res
  end

end