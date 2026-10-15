defmodule ExcloudWeb.PageControllerTest do
  use ExcloudWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    document = conn |> html_response(200) |> LazyHTML.from_document()
    assert document |> LazyHTML.query("#main-content #welcome-title") |> Enum.any?()
    assert document |> LazyHTML.query("#resources .app-resource-card") |> Enum.count() == 3

    assert document
           |> LazyHTML.query("#app-brand svg use[href='/images/bootstrap.svg#bootstrap-mark']")
           |> Enum.any?()

    assert document
           |> LazyHTML.query("#theme-toggle #theme-system[data-theme-value='system']")
           |> Enum.any?()

    assert document |> LazyHTML.query("script:not([src])") |> Enum.empty?()
  end

  test "the saved cookie applies the theme before JavaScript loads", %{conn: conn} do
    document =
      conn
      |> put_req_cookie("excloud_theme", "dark")
      |> get(~p"/")
      |> html_response(200)
      |> LazyHTML.from_document()

    assert document |> LazyHTML.query("html[data-bs-theme='dark']") |> Enum.any?()
  end

  test "an invalid theme cookie falls back to the system color scheme", %{conn: conn} do
    document =
      conn
      |> put_req_cookie("excloud_theme", "invalid")
      |> get(~p"/")
      |> html_response(200)
      |> LazyHTML.from_document()

    assert document |> LazyHTML.query("html[data-bs-theme]") |> Enum.empty?()
  end
end
