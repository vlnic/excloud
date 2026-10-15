defmodule Mix.Tasks.Excloud.Gen.Auth do
  @shortdoc "Generates Phoenix authentication with Bootstrap navigation"
  @moduledoc """
  Runs `mix phx.gen.auth` with the same arguments and converts its injected menu
  to Bootstrap. Phoenix 1.8 hardcodes that menu in its injector, so it cannot be
  overridden with the templates in `priv/templates/phx.gen.auth`.

      mix excloud.gen.auth Accounts User users --live
  """
  use Mix.Task

  @impl true
  def run(args) do
    Mix.Task.run("phx.gen.auth", args)

    root = "lib/excloud_web/components/layouts/root.html.heex"
    original = File.read!(root)

    updated =
      String.replace(
        original,
        "menu menu-horizontal w-full relative z-10 flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end",
        "app-auth-menu container d-flex flex-wrap align-items-center justify-content-end gap-3 list-unstyled py-3 mb-0"
      )

    if updated != original do
      File.write!(root, updated)
      Mix.shell().info("* updating #{root} with Bootstrap authentication navigation")
    end
  end
end
