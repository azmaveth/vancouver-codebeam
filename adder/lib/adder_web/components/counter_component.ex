defmodule AdderWeb.CounterComponent do
  use AdderWeb, :live_component

  alias Adder.Counter

  def mount(socket) do
    {:ok, Counter.mount("0", socket)}
  end

  def handle_event("counter:" <> event, _params, socket) do
    {:noreply, Counter.update(event, socket)}
  end

  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.counter value={Counter.show(@counter)}>
      <.counter_controls />
    </.counter>
    """
  end

  attr :value, :string, required: true
  slot :inner_block, required: true

  def counter(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-8 py-16">
      <h1 class="text-4xl font-bold">{@value}</h1>
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
