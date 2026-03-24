defmodule Adder.Counter do
  def new(value) when is_binary(value) do
    String.to_integer(value)
  end

  def add(value, addend) do
    value + addend
  end

  def show(value) do
    Integer.to_string(value)
  end
end
