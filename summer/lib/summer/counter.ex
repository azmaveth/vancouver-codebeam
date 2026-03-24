defmodule Summer.Counter do
  def new(input) do
    String.to_integer(input)
  end

  def increment(acc, item \\ 1) do
    acc + item
  end

  def show(acc) do
    "The ants arrrrr is #{acc}"
  end
end
