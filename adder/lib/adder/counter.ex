defmodule Adder.Counter do
  import Phoenix.Component, only: [assign: 3]

  def new(value) when is_binary(value) do
    String.to_integer(value)
  end

  def add(value, addend) do
    value + addend
  end

  def show(value) do
    Integer.to_string(value)
  end

  def mount(initial_value, socket) do
    assign(socket, :counter, new(initial_value))
  end

  def update("increment", socket) do
    assign(socket, :counter, add(socket.assigns.counter, 1))
  end

  def update("decrement", socket) do
    assign(socket, :counter, add(socket.assigns.counter, -1))
  end
end
