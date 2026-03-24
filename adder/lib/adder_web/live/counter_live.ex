defmodule AdderWeb.CounterLive do
  use AdderWeb, :live_view

  alias AdderWeb.CounterComponent

  def mount(_params, _session, socket) do
    {:ok, socket |> CounterComponent.mount("0")}
  end

  def handle_event("counter:" <> event, _params, socket) do
    {:noreply, socket |> CounterComponent.update_counter(event)}
  end

  def render(assigns) do
    ~H"""
    <CounterComponent.counter value={@counter}>
      <CounterComponent.counter_controls />
    </CounterComponent.counter>
    """
  end
end
