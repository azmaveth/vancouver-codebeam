defmodule NoThanksWeb.Plugs.PlayerSession do
  @moduledoc "Ensures every browser session has a stable unique player ID."

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :player_id) do
      conn
    else
      put_session(conn, :player_id, :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
    end
  end
end
