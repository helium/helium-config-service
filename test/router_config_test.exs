defmodule RouterConfigTest do
  use ExUnit.Case
  doctest RouterConfig

  test "greets the world" do
    assert RouterConfig.hello() == :world
  end
end
