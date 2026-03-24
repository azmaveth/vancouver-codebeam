defmodule NoThanksWeb.GameLive do
  use NoThanksWeb, :live_view

  alias NoThanks.{Game, GameServer}

  @impl true
  def mount(%{"id" => game_id}, session, socket) do
    player_id = Map.get(session, "player_id", socket.id)

    case GameServer.get_game(game_id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found.")
         |> push_navigate(to: ~p"/")}

      game ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(NoThanks.PubSub, "game:#{game_id}")
        end

        my_player = Game.player_by_id(game, player_id)
        view = compute_view(game, my_player)

        {:ok,
         socket
         |> assign(:player_id, player_id)
         |> assign(:game_id, game_id)
         |> assign(:game, game)
         |> assign(:my_player, my_player)
         |> assign(:view, view)
         |> assign(:my_turn, my_turn?(game, player_id))
         |> assign(:join_form, to_form(%{"name" => ""}, as: :join))
         |> assign(:join_error, nil)}
    end
  end

  @impl true
  def handle_info({:game_updated, game}, socket) do
    player_id = socket.assigns.player_id
    my_player = Game.player_by_id(game, player_id)

    {:noreply,
     socket
     |> assign(:game, game)
     |> assign(:my_player, my_player)
     |> assign(:view, compute_view(game, my_player))
     |> assign(:my_turn, my_turn?(game, player_id))}
  end

  @impl true
  def handle_event("join_game", %{"join" => %{"name" => name}}, socket) do
    name = String.trim(name)

    if name == "" do
      {:noreply, assign(socket, join_error: "Please enter your name")}
    else
      game_id = socket.assigns.game_id
      player_id = socket.assigns.player_id

      case GameServer.join(game_id, player_id, name) do
        {:ok, game} ->
          my_player = Game.player_by_id(game, player_id)

          {:noreply,
           socket
           |> assign(:game, game)
           |> assign(:my_player, my_player)
           |> assign(:view, compute_view(game, my_player))
           |> assign(:join_error, nil)}

        {:error, :game_full} ->
          {:noreply, assign(socket, join_error: "Game is full.")}

        {:error, :game_not_waiting} ->
          {:noreply, assign(socket, join_error: "Game has already started.")}

        _ ->
          {:noreply, assign(socket, join_error: "Could not join game.")}
      end
    end
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    case GameServer.start_game(socket.assigns.game_id, socket.assigns.player_id) do
      {:ok, game} ->
        my_player = Game.player_by_id(game, socket.assigns.player_id)

        {:noreply,
         socket
         |> assign(:game, game)
         |> assign(:my_player, my_player)
         |> assign(:view, :playing)
         |> assign(:my_turn, my_turn?(game, socket.assigns.player_id))}

      {:error, :not_enough_players} ->
        {:noreply, put_flash(socket, :error, "Need at least 3 players to start.")}

      {:error, :not_host} ->
        {:noreply, put_flash(socket, :error, "Only the host can start the game.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("take_card", _params, socket) do
    case GameServer.take_card(socket.assigns.game_id, socket.assigns.player_id) do
      {:ok, game} ->
        my_player = Game.player_by_id(game, socket.assigns.player_id)

        {:noreply,
         socket
         |> assign(:game, game)
         |> assign(:my_player, my_player)
         |> assign(:view, compute_view(game, my_player))
         |> assign(:my_turn, my_turn?(game, socket.assigns.player_id))}

      {:error, :not_your_turn} ->
        {:noreply, put_flash(socket, :error, "It's not your turn.")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("no_thanks", _params, socket) do
    case GameServer.no_thanks(socket.assigns.game_id, socket.assigns.player_id) do
      {:ok, game} ->
        my_player = Game.player_by_id(game, socket.assigns.player_id)

        {:noreply,
         socket
         |> assign(:game, game)
         |> assign(:my_player, my_player)
         |> assign(:my_turn, my_turn?(game, socket.assigns.player_id))}

      {:error, :not_your_turn} ->
        {:noreply, put_flash(socket, :error, "It's not your turn.")}

      {:error, :no_chips} ->
        {:noreply, put_flash(socket, :error, "You have no chips — you must take the card!")}

      _ ->
        {:noreply, socket}
    end
  end

  # Helpers

  defp compute_view(game, my_player) do
    cond do
      is_nil(my_player) && game.status == :waiting -> :join
      is_nil(my_player) -> :spectating
      game.status == :waiting -> :waiting
      game.status == :playing -> :playing
      true -> :finished
    end
  end

  defp my_turn?(game, player_id) do
    current = Game.current_player(game)
    game.status == :playing && current != nil && current.id == player_id
  end

  defp card_color_class(card) when card <= 12,
    do:
      "bg-gradient-to-br from-sky-50 to-blue-100 border-blue-300 text-blue-900 dark:from-blue-950 dark:to-blue-900 dark:border-blue-700 dark:text-blue-100"

  defp card_color_class(card) when card <= 24,
    do:
      "bg-gradient-to-br from-emerald-50 to-green-100 border-emerald-300 text-emerald-900 dark:from-emerald-950 dark:to-emerald-900 dark:border-emerald-700 dark:text-emerald-100"

  defp card_color_class(_),
    do:
      "bg-gradient-to-br from-rose-50 to-red-100 border-rose-300 text-rose-900 dark:from-rose-950 dark:to-rose-900 dark:border-rose-700 dark:text-rose-100"

  defp current_score(player) do
    Game.score_cards(player.cards) - player.chips
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-3xl mx-auto px-4 py-8">
        <%= cond do %>
          <% @view == :join -> %>
            <div class="max-w-sm mx-auto space-y-6">
              <div class="text-center space-y-1">
                <h2 class="text-2xl font-bold">Join Game</h2>
                <p class="text-base-content/50">
                  Code: <span class="font-mono font-black text-lg tracking-widest">{@game_id}</span>
                </p>
                <p class="text-sm text-base-content/40">
                  {length(@game.players)} player{if length(@game.players) != 1, do: "s", else: ""} waiting
                </p>
              </div>
              <.form
                for={@join_form}
                id="game-join-form"
                phx-submit="join_game"
                class="bg-base-200 rounded-2xl p-6 space-y-4"
              >
                <.input field={@join_form[:name]} label="Your Name" placeholder="Enter your name" />
                <p :if={@join_error} class="text-sm text-error -mt-1">{@join_error}</p>
                <button
                  type="submit"
                  class="w-full py-2.5 px-4 bg-primary text-primary-content font-semibold rounded-lg hover:opacity-90 transition-opacity"
                >
                  Join Game
                </button>
              </.form>
              <div class="text-center">
                <.link
                  navigate={~p"/"}
                  class="text-sm text-base-content/40 hover:text-base-content transition-colors"
                >
                  ← Back to lobby
                </.link>
              </div>
            </div>
          <% @view == :spectating -> %>
            <div class="text-center space-y-4 py-16">
              <p class="text-5xl">👀</p>
              <h2 class="text-2xl font-bold">Game in Progress</h2>
              <p class="text-base-content/50">This game has already started.</p>
              <.link
                navigate={~p"/"}
                class="inline-block mt-4 px-6 py-2.5 bg-primary text-primary-content font-semibold rounded-lg hover:opacity-90 transition-opacity"
              >
                Back to Lobby
              </.link>
            </div>
          <% @view == :waiting -> %>
            <div class="max-w-sm mx-auto space-y-6">
              <%!-- Game code --%>
              <div class="text-center space-y-1">
                <p class="text-xs uppercase tracking-widest text-base-content/40 font-semibold">
                  Game Code
                </p>
                <div class="text-6xl font-black font-mono tracking-widest">{@game_id}</div>
                <p class="text-sm text-base-content/40">Share this code to invite players</p>
              </div>

              <%!-- Player list --%>
              <div class="bg-base-200 rounded-2xl p-5 space-y-3">
                <div class="flex items-center justify-between text-sm">
                  <span class="font-semibold">
                    Players
                    <span class="text-base-content/40 font-normal">({length(@game.players)}/7)</span>
                  </span>
                  <span class="text-base-content/40">
                    <%= if length(@game.players) < 3 do %>
                      Need {3 - length(@game.players)} more
                    <% else %>
                      Ready!
                    <% end %>
                  </span>
                </div>

                <ul id="waiting-players" class="space-y-2">
                  <%= for {player, idx} <- Enum.with_index(@game.players) do %>
                    <li class="flex items-center gap-3 px-3 py-2 bg-base-100 rounded-xl">
                      <div class="w-7 h-7 rounded-full bg-primary/20 text-primary flex items-center justify-center text-xs font-bold flex-shrink-0">
                        {idx + 1}
                      </div>
                      <span class="font-medium flex-1 truncate">
                        {player.name}
                        <span :if={player.id == @player_id} class="text-xs text-base-content/40 ml-1">
                          (you)
                        </span>
                      </span>
                      <span :if={idx == 0} class="text-xs text-base-content/40">host</span>
                    </li>
                  <% end %>
                </ul>
              </div>

              <%!-- Start / waiting --%>
              <%= if @my_player && @my_player == Game.host(@game) do %>
                <div class="space-y-2">
                  <button
                    phx-click="start_game"
                    id="start-game-btn"
                    disabled={length(@game.players) < 3}
                    class={[
                      "w-full py-3 px-4 font-semibold rounded-xl transition-all text-lg",
                      length(@game.players) >= 3 &&
                        "bg-primary text-primary-content hover:opacity-90 shadow-lg hover:shadow-xl hover:-translate-y-0.5",
                      length(@game.players) < 3 &&
                        "bg-base-300 text-base-content/30 cursor-not-allowed"
                    ]}
                  >
                    Start Game
                  </button>
                  <p :if={length(@game.players) < 3} class="text-center text-xs text-base-content/40">
                    Minimum 3 players required
                  </p>
                </div>
              <% else %>
                <div class="text-center py-3 text-base-content/40 text-sm">
                  Waiting for the host to start…
                </div>
              <% end %>
            </div>
          <% @view == :playing -> %>
            <div class="space-y-6">
              <%!-- Top bar --%>
              <div class="flex items-center justify-between text-sm text-base-content/40">
                <span>
                  Game <span class="font-mono font-semibold text-base-content/70">{@game_id}</span>
                </span>
                <span>
                  {length(@game.deck)} card{if length(@game.deck) != 1, do: "s", else: ""} remaining
                </span>
              </div>

              <%!-- Turn indicator --%>
              <div class="flex justify-center">
                <%= if @my_turn do %>
                  <div class="inline-flex items-center gap-2 px-5 py-2 bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 rounded-full font-semibold">
                    <div class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                    Your turn!
                  </div>
                <% else %>
                  <div class="inline-flex items-center gap-2 px-5 py-2 bg-base-200 rounded-full text-base-content/50">
                    <div class="w-2 h-2 rounded-full bg-amber-400"></div>
                    {Game.current_player(@game).name}'s turn
                  </div>
                <% end %>
              </div>

              <%!-- Card + chips + buttons --%>
              <div class="flex flex-col items-center gap-5">
                <%!-- The card --%>
                <div class={[
                  "relative w-44 h-60 rounded-2xl border-2 shadow-2xl flex items-center justify-center select-none transition-transform duration-200 hover:scale-105",
                  card_color_class(@game.current_card)
                ]}>
                  <span class="text-7xl font-black">{@game.current_card}</span>
                  <span class="absolute top-3 left-4 text-base font-bold opacity-40">
                    {@game.current_card}
                  </span>
                  <span class="absolute bottom-3 right-4 text-base font-bold opacity-40 rotate-180">
                    {@game.current_card}
                  </span>
                </div>

                <%!-- Chips on card --%>
                <div class="flex items-center gap-3 min-h-7">
                  <%= if @game.chips_on_card > 0 do %>
                    <div class="flex gap-1 flex-wrap max-w-48 justify-center">
                      <%= for i <- 1..12, i <= @game.chips_on_card do %>
                        <div class="w-5 h-5 rounded-full bg-amber-400 border border-amber-600 shadow-sm">
                        </div>
                      <% end %>
                      <%= if @game.chips_on_card > 12 do %>
                        <span class="text-xs font-bold text-amber-600 self-center">
                          +{@game.chips_on_card - 12}
                        </span>
                      <% end %>
                    </div>
                    <span class="text-sm text-base-content/40">
                      {@game.chips_on_card} chip{if @game.chips_on_card != 1, do: "s", else: ""} on card
                    </span>
                  <% else %>
                    <span class="text-sm text-base-content/25 italic">No chips on card</span>
                  <% end %>
                </div>

                <%!-- Action buttons --%>
                <%= if @my_turn do %>
                  <div class="flex gap-3 flex-wrap justify-center">
                    <button
                      phx-click="take_card"
                      id="take-card-btn"
                      class="px-7 py-3 bg-emerald-500 hover:bg-emerald-600 active:bg-emerald-700 text-white font-semibold rounded-xl shadow-md hover:shadow-lg hover:-translate-y-0.5 active:translate-y-0 transition-all"
                    >
                      Take Card
                      <%= if @game.chips_on_card > 0 do %>
                        <span class="ml-1 opacity-80 text-sm">(+{@game.chips_on_card}🪙)</span>
                      <% end %>
                    </button>
                    <button
                      phx-click="no_thanks"
                      id="no-thanks-btn"
                      disabled={@my_player.chips == 0}
                      class={[
                        "px-7 py-3 font-semibold rounded-xl shadow-md transition-all",
                        @my_player.chips > 0 &&
                          "bg-rose-500 hover:bg-rose-600 active:bg-rose-700 text-white hover:shadow-lg hover:-translate-y-0.5 active:translate-y-0",
                        @my_player.chips == 0 &&
                          "bg-base-300 text-base-content/30 cursor-not-allowed"
                      ]}
                    >
                      No Thanks! <span class="ml-1 opacity-60 text-sm">(🪙{@my_player.chips})</span>
                    </button>
                  </div>
                <% end %>
              </div>

              <%!-- Players --%>
              <div class="space-y-2">
                <h3 class="text-xs font-semibold text-base-content/40 uppercase tracking-wider">
                  Players
                </h3>
                <div class="bg-base-200 rounded-2xl overflow-hidden divide-y divide-base-300">
                  <%= for {player, idx} <- Enum.with_index(@game.players) do %>
                    <div class={[
                      "flex items-center gap-3 px-4 py-3 transition-colors",
                      idx == @game.current_player_index && "bg-emerald-500/5"
                    ]}>
                      <%!-- Turn dot --%>
                      <div class="w-2 flex-shrink-0">
                        <%= if idx == @game.current_player_index do %>
                          <div class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                        <% else %>
                          <div class="w-2 h-2"></div>
                        <% end %>
                      </div>

                      <%!-- Name --%>
                      <span class={[
                        "font-medium w-24 truncate flex-shrink-0 text-sm",
                        player.id == @player_id && "text-primary"
                      ]}>
                        {player.name}
                        <span :if={player.id == @player_id} class="text-xs opacity-50">(you)</span>
                      </span>

                      <%!-- Chips --%>
                      <div class="flex items-center gap-1 flex-shrink-0 min-w-10">
                        <div class="w-3.5 h-3.5 rounded-full bg-amber-400 border border-amber-600 flex-shrink-0">
                        </div>
                        <span class="text-sm font-semibold">{player.chips}</span>
                      </div>

                      <%!-- Cards as runs --%>
                      <div class="flex gap-1 flex-wrap flex-1 min-w-0">
                        <%= for run <- Game.card_runs(player.cards) do %>
                          <div class="flex">
                            <%= for {card, i} <- Enum.with_index(run) do %>
                              <span class={[
                                "text-xs font-bold px-1.5 py-0.5",
                                length(run) == 1 && "rounded bg-base-300",
                                length(run) > 1 &&
                                  "bg-emerald-200 dark:bg-emerald-800 text-emerald-900 dark:text-emerald-100",
                                length(run) > 1 && i == 0 && "rounded-l",
                                length(run) > 1 && i == length(run) - 1 && "rounded-r",
                                i > 0 && "border-l border-emerald-300 dark:border-emerald-700"
                              ]}>
                                {card}
                              </span>
                            <% end %>
                          </div>
                        <% end %>
                        <span :if={player.cards == []} class="text-xs text-base-content/20">—</span>
                      </div>

                      <%!-- Score --%>
                      <span class="text-xs text-base-content/40 flex-shrink-0">
                        {current_score(player)} pts
                      </span>
                    </div>
                  <% end %>
                </div>
              </div>

              <%!-- Action log --%>
              <%= if @game.log != [] do %>
                <div class="space-y-1">
                  <h3 class="text-xs font-semibold text-base-content/40 uppercase tracking-wider">
                    Recent
                  </h3>
                  <div class="space-y-0.5">
                    <%= for {entry, i} <- Enum.with_index(@game.log) do %>
                      <p class={[
                        "text-xs transition-opacity",
                        i == 0 && "text-base-content/70",
                        i > 0 && "text-base-content/30"
                      ]}>
                        {entry}
                      </p>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          <% @view == :finished -> %>
            <div class="space-y-6">
              <div class="text-center space-y-1">
                <div class="text-5xl mb-3">🎉</div>
                <h2 class="text-4xl font-black">Game Over!</h2>
                <p class="text-base-content/50">Final scores — lowest wins</p>
              </div>

              <%!-- Scoreboard --%>
              <div class="space-y-3">
                <%= for {result, rank} <- Enum.with_index(Game.scores(@game)) do %>
                  <div class={[
                    "flex items-center gap-4 p-4 rounded-2xl border-2 transition-all",
                    rank == 0 && "border-amber-400 bg-amber-50 dark:bg-amber-950/30",
                    rank != 0 && result.player.id == @player_id && "border-primary/40 bg-base-200",
                    rank != 0 && result.player.id != @player_id && "border-base-300 bg-base-200"
                  ]}>
                    <div class={[
                      "w-9 h-9 rounded-full flex items-center justify-center font-bold text-sm flex-shrink-0",
                      rank == 0 && "bg-amber-400 text-amber-900",
                      rank != 0 && "bg-base-300 text-base-content/60"
                    ]}>
                      {rank + 1}
                    </div>
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2 flex-wrap">
                        <span class="font-semibold">{result.player.name}</span>
                        <span :if={result.player.id == @player_id} class="text-xs text-primary">
                          (you)
                        </span>
                        <span :if={rank == 0} class="text-base">👑</span>
                      </div>
                      <div class="text-xs text-base-content/50 mt-0.5">
                        Cards: {result.card_score} pts · Chips saved: {result.chip_count}
                      </div>
                      <%!-- Show their cards --%>
                      <div class="flex gap-1 flex-wrap mt-1.5">
                        <%= for run <- Game.card_runs(result.player.cards) do %>
                          <div class="flex">
                            <%= for {card, i} <- Enum.with_index(run) do %>
                              <span class={[
                                "text-xs font-bold px-1.5 py-0.5",
                                length(run) == 1 && "rounded bg-base-300",
                                length(run) > 1 &&
                                  "bg-emerald-200 dark:bg-emerald-800 text-emerald-900 dark:text-emerald-100",
                                length(run) > 1 && i == 0 && "rounded-l",
                                length(run) > 1 && i == length(run) - 1 && "rounded-r",
                                i > 0 && "border-l border-emerald-300 dark:border-emerald-700"
                              ]}>
                                {card}
                              </span>
                            <% end %>
                          </div>
                        <% end %>
                      </div>
                    </div>
                    <div class={[
                      "text-3xl font-black flex-shrink-0",
                      rank == 0 && "text-amber-600 dark:text-amber-400",
                      rank != 0 && "text-base-content"
                    ]}>
                      {result.total}
                    </div>
                  </div>
                <% end %>
              </div>

              <%!-- Removed cards reveal --%>
              <div class="bg-base-200 rounded-2xl p-4 space-y-2">
                <p class="text-xs font-semibold text-base-content/40 uppercase tracking-wider">
                  Hidden cards (removed before play)
                </p>
                <div class="flex gap-2 flex-wrap">
                  <%= for card <- Enum.sort(@game.removed_cards) do %>
                    <span class="text-sm font-bold px-2 py-0.5 bg-base-300 rounded text-base-content/50">
                      {card}
                    </span>
                  <% end %>
                </div>
              </div>

              <div class="flex justify-center">
                <.link
                  navigate={~p"/"}
                  class="px-8 py-3 bg-primary text-primary-content font-semibold rounded-xl hover:opacity-90 transition-opacity shadow-md"
                >
                  New Game
                </.link>
              </div>
            </div>
          <% true -> %>
            <div class="flex justify-center py-16">
              <p class="text-base-content/40">Loading…</p>
            </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end
