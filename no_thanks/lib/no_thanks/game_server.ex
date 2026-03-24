defmodule NoThanks.GameServer do
  @moduledoc "GenServer managing a single No Thanks! game instance."

  use GenServer

  alias NoThanks.Game

  # Client API

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  defp via_tuple(game_id) do
    {:via, Registry, {NoThanks.GameRegistry, game_id}}
  end

  def game_exists?(game_id) do
    case Registry.lookup(NoThanks.GameRegistry, game_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  def get_game(game_id) do
    try do
      GenServer.call(via_tuple(game_id), :get_game)
    catch
      :exit, _ -> nil
    end
  end

  def join(game_id, player_id, name) do
    GenServer.call(via_tuple(game_id), {:join, player_id, name})
  end

  def start_game(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:start_game, player_id})
  end

  def take_card(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:take_card, player_id})
  end

  def no_thanks(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:no_thanks, player_id})
  end

  # Server callbacks

  @impl true
  def init(game_id) do
    {:ok, Game.new(game_id)}
  end

  @impl true
  def handle_call(:get_game, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call({:join, player_id, name}, _from, game) do
    case Game.add_player(game, player_id, name) do
      {:ok, new_game} ->
        broadcast(new_game)
        {:reply, {:ok, new_game}, new_game}

      error ->
        {:reply, error, game}
    end
  end

  @impl true
  def handle_call({:start_game, player_id}, _from, game) do
    host = Game.host(game)

    if host && host.id == player_id do
      case Game.start(game) do
        {:ok, new_game} ->
          broadcast(new_game)
          {:reply, {:ok, new_game}, new_game}

        error ->
          {:reply, error, game}
      end
    else
      {:reply, {:error, :not_host}, game}
    end
  end

  @impl true
  def handle_call({:take_card, player_id}, _from, game) do
    case Game.take_card(game, player_id) do
      {:ok, new_game} ->
        broadcast(new_game)
        {:reply, {:ok, new_game}, new_game}

      error ->
        {:reply, error, game}
    end
  end

  @impl true
  def handle_call({:no_thanks, player_id}, _from, game) do
    case Game.no_thanks(game, player_id) do
      {:ok, new_game} ->
        broadcast(new_game)
        {:reply, {:ok, new_game}, new_game}

      error ->
        {:reply, error, game}
    end
  end

  defp broadcast(game) do
    Phoenix.PubSub.broadcast(NoThanks.PubSub, "game:#{game.id}", {:game_updated, game})
  end
end
