defmodule AdderWeb.PageController do
  use AdderWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
