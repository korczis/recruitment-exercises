defmodule EqLabs.CacheTest do
  use ExUnit.Case
  alias EqLabs.Cache

  @table_name :eq_labs_cache

#  test "register_function/4 and get/1" do
#    {:ok, cache} = Cache.start_link()
#    assert {:ok, _} = Cache.register_function(fn -> {:ok, :value} end, :key, 1000, 500)
#
#    assert {:ok, :value} = Cache.Store.get(@table_name, :key)
#    assert {:ok, :value} = Cache.Store.get(@table_name, :key)
#    assert {:ok, :value} = Cache.Store.get(@table_name, :key)
#  end
#
#  test "register_function/4, get/1 and refresh" do
#    {:ok, cache} = Cache.start_link()
#    assert {:ok, _} = Cache.register_function(fn -> {:ok, :value} end, :key, 1000, 500)
#
#    assert {:ok, :value} = Cache.Store.get(@table_name, :key)
#    assert {:ok, :value} = Cache.Store.get(@table_name, :key)
#    assert {:ok, :value} = Cache.Store.get(@table_name, :key)
#
#    # Wait for the refresh to happen
#    :timer.sleep(600)
#    assert {:ok, :value} = Cache.Store.get(@table_name, :key)
#  end
#
#  test "get/1 with timeout" do
#    {:ok, cache} = Cache.start_link()
#    assert {:ok, _} = Cache.register_function(fn -> :timer.sleep(200); {:ok, :value} end, :key, 1000, 500)
#
#    assert {:ok, :value} = Cache.Store.get(@table_name, :key, 100)
#    assert {:error, :timeout} = Cache.Store.get(@table_name, :key, 100)
#  end
#
#  test "get/1 with not_registered" do
#    _ = Cache.start_link()
#
#    assert {:error, :not_registered} = Cache.get(:key)
#  end
end
