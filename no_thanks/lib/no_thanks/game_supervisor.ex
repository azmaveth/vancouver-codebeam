defmodule NoThanks.GameSupervisor do
  @moduledoc "DynamicSupervisor for No Thanks! game processes."

  use DynamicSupervisor

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(game_id) do
    DynamicSupervisor.start_child(__MODULE__, {NoThanks.GameServer, game_id})
  end
end
