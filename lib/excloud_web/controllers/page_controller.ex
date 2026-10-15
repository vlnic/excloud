defmodule ExcloudWeb.PageController do
  use ExcloudWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
