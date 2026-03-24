defmodule NoThanksWeb.PageController do
  use NoThanksWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
