defmodule NoThanksWeb.LobbyLive do
  use NoThanksWeb, :live_view

  alias NoThanks.{GameServer, GameSupervisor}

  @impl true
  def mount(_params, session, socket) do
    player_id = Map.get(session, "player_id", socket.id)

    {:ok,
     assign(socket,
       player_id: player_id,
       create_form: to_form(%{"name" => ""}, as: :create),
       join_form: to_form(%{"name" => "", "code" => ""}, as: :join),
       create_error: nil,
       join_error: nil
     )}
  end

  @impl true
  def handle_event("create_game", %{"create" => %{"name" => name}}, socket) do
    name = String.trim(name)

    if name == "" do
      {:noreply, assign(socket, create_error: "Please enter your name")}
    else
      case do_create_game(socket.assigns.player_id, name) do
        {:ok, game_id} ->
          {:noreply, push_navigate(socket, to: ~p"/games/#{game_id}")}

        {:error, _} ->
          {:noreply, assign(socket, create_error: "Failed to create game. Please try again.")}
      end
    end
  end

  @impl true
  def handle_event("join_game", %{"join" => %{"name" => name, "code" => code}}, socket) do
    name = String.trim(name)
    code = code |> String.trim() |> String.upcase()

    cond do
      name == "" ->
        {:noreply, assign(socket, join_error: "Please enter your name")}

      String.length(code) != 4 ->
        {:noreply, assign(socket, join_error: "Game code must be 4 letters")}

      not GameServer.game_exists?(code) ->
        {:noreply, assign(socket, join_error: "Game not found. Check the code and try again.")}

      true ->
        case GameServer.join(code, socket.assigns.player_id, name) do
          {:ok, _game} ->
            {:noreply, push_navigate(socket, to: ~p"/games/#{code}")}

          {:error, :game_full} ->
            {:noreply, assign(socket, join_error: "This game is full (max 7 players).")}

          {:error, :game_not_waiting} ->
            {:noreply, assign(socket, join_error: "This game has already started.")}

          _ ->
            {:noreply, assign(socket, join_error: "Could not join game.")}
        end
    end
  end

  defp do_create_game(player_id, name) do
    game_id = for(_ <- 1..4, into: "", do: <<Enum.random(?A..?Z)>>)

    case GameSupervisor.start_game(game_id) do
      {:ok, _pid} ->
        {:ok, _game} = GameServer.join(game_id, player_id, name)
        {:ok, game_id}

      {:error, {:already_started, _}} ->
        do_create_game(player_id, name)

      error ->
        error
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="min-h-[calc(100vh-3.5rem)] flex items-center justify-center px-4 py-12">
        <div class="w-full max-w-md space-y-8">
          <%!-- Title --%>
          <div class="text-center space-y-2">
            <h1 class="text-6xl font-black tracking-tight">No Thanks!</h1>
            <p class="text-base-content/60 text-lg">The push-your-luck card game</p>
            <p class="text-base-content/40 text-sm">3–7 players · ~20 minutes · Lowest score wins</p>
          </div>

          <%!-- Create game --%>
          <div class="bg-base-200 rounded-2xl p-6 space-y-4">
            <div>
              <h2 class="text-lg font-semibold">Create a Game</h2>
              <p class="text-sm text-base-content/50">
                Start a new game and share the code with friends
              </p>
            </div>
            <.form for={@create_form} id="create-form" phx-submit="create_game" class="space-y-3">
              <.input field={@create_form[:name]} label="Your Name" placeholder="Enter your name" />
              <p :if={@create_error} class="text-sm text-error -mt-1">{@create_error}</p>
              <button
                type="submit"
                class="w-full py-2.5 px-4 bg-primary text-primary-content font-semibold rounded-lg hover:opacity-90 active:opacity-80 transition-opacity"
              >
                Create Game
              </button>
            </.form>
          </div>

          <%!-- Divider --%>
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-base-300"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="px-3 bg-base-100 text-base-content/40">or join an existing game</span>
            </div>
          </div>

          <%!-- Join game --%>
          <div class="bg-base-200 rounded-2xl p-6 space-y-4">
            <div>
              <h2 class="text-lg font-semibold">Join a Game</h2>
              <p class="text-sm text-base-content/50">Enter the 4-letter code from your host</p>
            </div>
            <.form for={@join_form} id="join-form" phx-submit="join_game" class="space-y-3">
              <.input field={@join_form[:name]} label="Your Name" placeholder="Enter your name" />
              <.input
                field={@join_form[:code]}
                label="Game Code"
                placeholder="ABCD"
                class="w-full input uppercase tracking-widest font-mono text-lg"
              />
              <p :if={@join_error} class="text-sm text-error -mt-1">{@join_error}</p>
              <button
                type="submit"
                class="w-full py-2.5 px-4 bg-base-content text-base-100 font-semibold rounded-lg hover:opacity-80 active:opacity-70 transition-opacity"
              >
                Join Game
              </button>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
