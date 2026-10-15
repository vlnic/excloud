defmodule ExcloudWeb.Layouts do
  @moduledoc """
  Application layouts, connection notices and the Bootstrap color mode switcher.
  """
  use ExcloudWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header id="app-header" class="app-header border-bottom">
      <nav
        class="container d-flex flex-wrap align-items-center justify-content-between gap-3 py-4"
        aria-label={gettext("Main navigation")}
      >
        <.link
          href={~p"/"}
          id="app-brand"
          class="app-brand d-flex align-items-center gap-3 text-decoration-none"
        >
          <span class="app-brand-mark"><.icon name="bootstrap" /></span>
          <span class="fw-semibold">Excloud<span class="app-brand-caption">Phoenix + Bootstrap</span></span>
        </.link>
        <div class="d-flex flex-wrap align-items-center gap-3">
          <a href="https://github.com/phoenixframework/phoenix" class="app-nav-link">GitHub</a>
          <.theme_toggle />
          <a
            id="header-get-started"
            href="https://phoenix.hexdocs.pm/overview.html"
            class="btn-solid theme-primary btn-sm"
          >Get started <span aria-hidden="true">↗</span></a>
        </div>
      </nav>
    </header>
    <main id="main-content" class="container app-main">
      {render_slot(@inner_block)}
    </main>
    <footer class="container app-footer border-top d-flex flex-wrap justify-content-between gap-2 py-4">
      <span>Built with Phoenix. Styled with Bootstrap.</span>
      <a href="https://phoenixframework.org/" class="app-nav-link">Phoenix v{Application.spec(
        :phoenix,
        :vsn
      )}</a>
    </footer>
    <.flash_group flash={@flash} />
    """
  end

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} class="app-flash-stack" aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="app-spin" />
      </.flash>
      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="app-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div id="theme-toggle" class="app-theme-toggle" role="group" aria-label={gettext("Color theme")}>
      <button
        :for={
          {theme, label} <- [
            {"system", gettext("System")},
            {"light", gettext("Light")},
            {"dark", gettext("Dark")}
          ]
        }
        id={"theme-#{theme}"}
        type="button"
        data-theme-value={theme}
        aria-pressed="false"
        class="app-theme-option"
      >{label}</button>
    </div>
    """
  end

  defp theme_from_cookie(conn) do
    conn = Plug.Conn.fetch_cookies(conn)

    case conn.req_cookies["excloud_theme"] do
      theme when theme in ["light", "dark"] -> theme
      _ -> nil
    end
  end
end
