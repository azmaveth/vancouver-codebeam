defmodule NoThanksWeb.LobbyLiveTest do
  use NoThanksWeb.ConnCase
  import Phoenix.LiveViewTest

  test "GET / renders the lobby", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "No Thanks!"
    assert html =~ "Create a Game"
    assert html =~ "Join a Game"
  end
end
