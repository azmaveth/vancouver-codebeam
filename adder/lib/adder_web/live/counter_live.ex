defmodule AdderWeb.CounterLive do
  use AdderWeb, :live_view

  def render(assigns) do
    ~H"""
    <.live_component module={AdderWeb.CounterComponent} id="counter" />
    """
  end
end
