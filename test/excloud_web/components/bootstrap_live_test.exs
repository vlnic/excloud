defmodule ExcloudWeb.BootstrapLiveTest do
  use ExcloudWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "successful submits show a flash that can be dismissed through LiveView", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ExcloudWeb.BootstrapPreviewLive)

    view
    |> form("#preview-form", preview: %{email: "ada@example.com", accepted: true})
    |> render_submit()

    assert has_element?(view, "#flash-info.alert.theme-info[role='alert']")
    assert has_element?(view, "#flash-info-dismiss[aria-label]")
    view |> element("#flash-info-dismiss") |> render_click()
    refute has_element?(view, "#flash-info")
    assert has_element?(view, "#client-error[hidden][phx-disconnected][phx-connected]")
    assert has_element?(view, "#server-error[hidden][phx-disconnected][phx-connected]")
  end

  test "table rows remain responsive and support stream inserts and deletes", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ExcloudWeb.BootstrapPreviewLive)

    assert has_element?(
             view,
             ".table-responsive table.table-striped #preview-records[phx-update='stream']"
           )

    assert has_element?(view, "#records-1")
    view |> element("#preview-add") |> render_click()
    assert has_element?(view, "#records-1")
    assert has_element?(view, "#records-2")
    view |> element("#remove-1") |> render_click()
    refute has_element?(view, "#records-1")
    assert has_element?(view, "#records-2")
  end
end
