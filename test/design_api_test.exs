defmodule DesignApiTest do
  use ExUnit.Case
  doctest DesignApi

  test "greets the world" do
    assert DesignApi.hello() == :world
  end
end
