#defmodule EqLabs.FunctionRegistryTest do
#  use ExUnit.Case
#  import EqLabs.FunctionRegistry
#
#  test "register and fetch function" do
#    key = "example_key"
#    function = fn -> IO.puts("example function") end
#
#    # Test register function
#    assert {:ok, _pid} = register(key, function)
#
#    # Test fetch_function
#    assert {_pid, {key, function, [ttl: 5, refresh_interval: 10]}} = fetch_function(key)
#  end
#
#  test "fetch all functions" do
#    key1 = "example_key_1"
#    function1 = fn -> IO.puts("example function 1") end
#
#    key2 = "example_key_2"
#    function2 = fn -> IO.puts("example function 2") end
#
#    # Register functions
#    assert {:ok, _pid1} = register(key1, function1)
#    assert {:ok, _pid2} = register(key2, function2)
#
#    # Test fetch_all_functions
#    functions = fetch_all_functions()
#    assert length(functions) == 2
#    assert functions == [
#             {key2, function2, [ttl: 5, refresh_interval: 10]},
#             {key1, function1, [ttl: 5, refresh_interval: 10]}
#           ]
#  end
#end
