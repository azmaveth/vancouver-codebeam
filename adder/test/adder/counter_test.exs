defmodule Adder.CounterTest do
  use ExUnit.Case, async: true

  alias Adder.Counter

  describe "new/1" do
    test "converts a string to an integer" do
      assert Counter.new("42") == 42
    end

    test "converts a negative string to an integer" do
      assert Counter.new("-5") == -5
    end

    test "converts zero string to integer" do
      assert Counter.new("0") == 0
    end
  end

  describe "add/2" do
    test "adds two values" do
      assert Counter.add(1, 2) == 3
    end

    test "adds a negative value" do
      assert Counter.add(5, -3) == 2
    end
  end

  describe "show/1" do
    test "converts an integer to a string" do
      assert Counter.show(42) == "42"
    end
  end

  describe "pipeline" do
    test "works end to end with pipes" do
      result =
        "1"
        |> Counter.new()
        |> Counter.add(2)
        |> Counter.show()

      assert result == "3"
    end
  end
end
