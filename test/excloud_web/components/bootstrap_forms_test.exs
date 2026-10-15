defmodule ExcloudWeb.BootstrapFormsTest do
  @moduledoc false

  use ExcloudWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "form controls keep their values, labels and navigation behavior", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ExcloudWeb.BootstrapPreviewLive)

    assert has_element?(view, "#preview-form input#preview_email.form-control")
    assert has_element?(view, "label[for='preview_email']")
    assert has_element?(view, "#preview_role.form-control option[value='reader'][selected]")
    assert has_element?(view, "#preview_notes.form-control")
    assert has_element?(view, "#preview_accepted.check")

    assert has_element?(
      view,
      "#preview-form input[type='hidden'][name='preview[accepted]'][value='false']"
    )

    assert has_element?(view, "#preview-save.btn-solid.theme-primary[phx-disable-with]")
    assert has_element?(view, "a#preview-home[href='/'][data-phx-link='redirect']")
    assert has_element?(view, "#disabled-check[disabled]")
    assert has_element?(view, "input[type='hidden'][name='disabled_check'][disabled]")
    assert has_element?(view, "#hidden-input[type='hidden'][value='token']")
    assert has_element?(view, "#custom-input.custom-control[value='custom value']")
    refute has_element?(view, "#custom-input.form-control")
    assert has_element?(view, "#multiple-input[multiple] option[value='editor'][selected]")
    refute has_element?(view, "#preview_email.is-invalid")
  end

  test "LiveView validation marks fields and links their feedback accessibly", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, ExcloudWeb.BootstrapPreviewLive)

    view
    |> form("#preview-form",
      preview: %{email: "invalid", accepted: false, notes: "Keep this text"}
    )
    |> render_change()

    assert has_element?(view, "#preview_email.form-control.is-invalid[aria-invalid='true']")

    assert has_element?(
      view,
      "#preview_email[aria-describedby='email-help preview_email-errors']"
    )

    assert has_element?(view, "#preview_email-errors.invalid-feedback")

    assert has_element?(
      view,
      "#preview_accepted.check.is-invalid[aria-describedby='preview_accepted-errors']"
    )

    assert has_element?(view, "#preview_accepted-errors.invalid-feedback")
    assert has_element?(view, "#preview_notes", "Keep this text")

    view
    |> form("#preview-form", preview: %{email: "ada@example.com", accepted: true, role: "editor"})
    |> render_change()

    refute has_element?(view, "#preview_email.is-invalid")
    refute has_element?(view, "#preview_email-errors")
    assert has_element?(view, "#preview_email[aria-describedby='email-help']")
    assert has_element?(view, "#preview_accepted[checked]")
    assert has_element?(view, "#preview_role option[value='editor'][selected]")
  end
end
