defmodule AdderWeb.CounterLive do
  use AdderWeb, :live_view

  alias Adder.Counter

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :counter, Counter.new("0"))}
  end

  def handle_event("increment", _params, socket) do
    counter = Counter.add(socket.assigns.counter, 1)
    {:noreply, assign(socket, :counter, counter)}
  end

  def handle_event("decrement", _params, socket) do
    counter = Counter.add(socket.assigns.counter, -1)
    {:noreply, assign(socket, :counter, counter)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-8 py-16">
      <h1 class="text-4xl font-bold">{Counter.show(@counter)}</h1>
      <div class="flex gap-4">
        <button
          phx-click="decrement"
          class="rounded-lg bg-zinc-900 px-6 py-3 text-white hover:bg-zinc-700"
        >
          -1
        </button>
        <button
          phx-click="increment"
          class="rounded-lg bg-zinc-900 px-6 py-3 text-white hover:bg-zinc-700"
        >
          +1
        </button>
      </div>
    </div>
    """
  end
end
