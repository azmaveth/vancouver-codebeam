defmodule AdderWeb.CounterLiveTest do
  use AdderWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders initial count of 0", %{conn: conn} do
    {:ok, view, html} = live(conn, "/counter")
    assert html =~ "0"
    assert has_element?(view, "h1", "0")
  end

  test "increments the counter", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/counter")

    view |> element("button", "+1") |> render_click()
    assert has_element?(view, "h1", "1")

    view |> element("button", "+1") |> render_click()
    assert has_element?(view, "h1", "2")
  end

  test "decrements the counter", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/counter")

    view |> element("button", "-1") |> render_click()
    assert has_element?(view, "h1", "-1")
  end

  test "increments and decrements together", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/counter")

    view |> element("button", "+1") |> render_click()
    view |> element("button", "+1") |> render_click()
    view |> element("button", "-1") |> render_click()
    assert has_element?(view, "h1", "1")
  end
end
