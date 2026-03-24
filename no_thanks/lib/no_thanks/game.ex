defmodule NoThanks.Game do
  @moduledoc """
  Pure game state and logic for No Thanks!

  33 cards (3–35), 9 removed at random before play. Each player starts with chips
  (11 for 3–5 players, 9 for 6, 7 for 7). On your turn: take the face-up card
  (collecting all chips on it) or say "No Thanks!" and spend one chip. If you
  have no chips you must take the card. After taking, you flip the next card and
  go again. Consecutive card runs only score the lowest card. Each remaining chip
  = −1 point. Lowest score wins.
  """

  @all_cards Enum.to_list(3..35)
  @cards_to_remove 9

  defstruct [
    :id,
    status: :waiting,
    players: [],
    deck: [],
    current_card: nil,
    chips_on_card: 0,
    current_player_index: 0,
    removed_cards: [],
    log: []
  ]

  @doc "Create a new game with the given ID."
  def new(id), do: %__MODULE__{id: id}

  @doc "Add a player to a waiting game. Idempotent if already joined."
  def add_player(%__MODULE__{status: :waiting} = game, player_id, name) do
    cond do
      length(game.players) >= 7 ->
        {:error, :game_full}

      Enum.any?(game.players, &(&1.id == player_id)) ->
        {:ok, game}

      true ->
        player = %{id: player_id, name: name, chips: 0, cards: []}
        {:ok, %{game | players: game.players ++ [player]}}
    end
  end

  def add_player(_game, _player_id, _name), do: {:error, :game_not_waiting}

  @doc "Start the game. Requires 3–7 players."
  def start(%__MODULE__{status: :waiting, players: players} = game)
      when length(players) >= 3 and length(players) <= 7 do
    shuffled = Enum.shuffle(@all_cards)
    {removed, deck_cards} = Enum.split(shuffled, @cards_to_remove)
    [first | rest] = deck_cards
    chips_each = chips_per_player(length(players))

    {:ok,
     %{
       game
       | status: :playing,
         players: Enum.map(players, &%{&1 | chips: chips_each}),
         deck: rest,
         current_card: first,
         chips_on_card: 0,
         current_player_index: 0,
         removed_cards: removed,
         log: ["Game started! #{length(deck_cards)} cards in play."]
     }}
  end

  def start(%__MODULE__{status: :waiting}), do: {:error, :not_enough_players}
  def start(_), do: {:error, :cannot_start}

  @doc "Active player takes the current card and any chips on it."
  def take_card(%__MODULE__{status: :playing} = game, player_id) do
    player = current_player(game)

    if player.id != player_id do
      {:error, :not_your_turn}
    else
      updated = %{
        player
        | cards: [game.current_card | player.cards],
          chips: player.chips + game.chips_on_card
      }

      players = List.replace_at(game.players, game.current_player_index, updated)

      entry =
        if game.chips_on_card > 0,
          do: "#{player.name} took #{game.current_card} (+#{game.chips_on_card} chips)",
          else: "#{player.name} took #{game.current_card}"

      case game.deck do
        [] ->
          {:ok,
           %{
             game
             | status: :finished,
               players: players,
               current_card: nil,
               chips_on_card: 0,
               log: prepend_log(game.log, entry <> " — Game over!")
           }}

        [next | rest] ->
          {:ok,
           %{
             game
             | players: players,
               deck: rest,
               current_card: next,
               chips_on_card: 0,
               log: prepend_log(game.log, entry)
           }}
      end
    end
  end

  def take_card(_game, _player_id), do: {:error, :game_not_playing}

  @doc "Active player says 'No Thanks!' and places one chip on the card."
  def no_thanks(%__MODULE__{status: :playing} = game, player_id) do
    player = current_player(game)

    cond do
      player.id != player_id ->
        {:error, :not_your_turn}

      player.chips == 0 ->
        {:error, :no_chips}

      true ->
        players =
          List.replace_at(game.players, game.current_player_index, %{
            player
            | chips: player.chips - 1
          })

        next_index = rem(game.current_player_index + 1, length(players))
        total_on_card = game.chips_on_card + 1

        entry =
          "#{player.name} said No Thanks! (#{total_on_card} chip#{if total_on_card != 1, do: "s", else: ""} on card)"

        {:ok,
         %{
           game
           | players: players,
             chips_on_card: total_on_card,
             current_player_index: next_index,
             log: prepend_log(game.log, entry)
         }}
    end
  end

  def no_thanks(_game, _player_id), do: {:error, :game_not_playing}

  @doc "Returns the current active player."
  def current_player(%__MODULE__{players: players, current_player_index: idx}) do
    Enum.at(players, idx)
  end

  @doc "Returns the player struct for the given ID, or nil."
  def player_by_id(%__MODULE__{players: players}, player_id) do
    Enum.find(players, &(&1.id == player_id))
  end

  @doc "Returns the host (first player to join)."
  def host(%__MODULE__{players: [h | _]}), do: h
  def host(_), do: nil

  @doc "Returns a sorted list of score results (lowest total first)."
  def scores(%__MODULE__{players: players}) do
    players
    |> Enum.map(fn p ->
      card_score = score_cards(p.cards)
      %{player: p, card_score: card_score, chip_count: p.chips, total: card_score - p.chips}
    end)
    |> Enum.sort_by(& &1.total)
  end

  @doc "Computes a player's card score. Consecutive runs only count the lowest card."
  def score_cards(cards) do
    cards
    |> Enum.sort()
    |> Enum.reduce({0, nil}, fn card, {total, prev} ->
      if prev && card == prev + 1, do: {total, card}, else: {total + card, card}
    end)
    |> elem(0)
  end

  @doc "Groups sorted cards into consecutive runs for display."
  def card_runs(cards) do
    cards
    |> Enum.sort()
    |> Enum.reduce([], fn card, runs ->
      case runs do
        [] ->
          [[card]]

        [run | rest] ->
          if List.last(run) == card - 1,
            do: [run ++ [card] | rest],
            else: [[card] | runs]
      end
    end)
    |> Enum.reverse()
  end

  defp chips_per_player(n) when n <= 5, do: 11
  defp chips_per_player(6), do: 9
  defp chips_per_player(_), do: 7

  defp prepend_log(log, entry), do: [entry | log] |> Enum.take(8)
end
