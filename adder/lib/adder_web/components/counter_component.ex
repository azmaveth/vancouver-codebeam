defmodule AdderWeb.CounterComponent do
  use Phoenix.Component

  alias Adder.Counter

  def mount(socket, initial_value) do
    assign(socket, :counter, Counter.new(initial_value))
  end

  def update_counter(socket, "increment") do
    assign(socket, :counter, Counter.add(socket.assigns.counter, 1))
  end

  def update_counter(socket, "decrement") do
    assign(socket, :counter, Counter.add(socket.assigns.counter, -1))
  end

  attr :value, :integer, required: true
  slot :inner_block, required: true

  def counter(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-8 py-16">
      <h1 class="text-4xl font-bold">{Counter.show(@value)}</h1>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def counter_controls(assigns) do
    ~H"""
    <div class="flex gap-4">
      <button
        phx-click="counter:decrement"
        class="rounded-lg bg-zinc-900 px-6 py-3 text-white hover:bg-zinc-700"
      >
        -1
      </button>
      <button
        phx-click="counter:increment"
        class="rounded-lg bg-zinc-900 px-6 py-3 text-white hover:bg-zinc-700"
      >
        +1
      </button>
    </div>
    """
  end
end
