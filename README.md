# Excloud

To start your Phoenix server:

* Install Elixir/Erlang, PostgreSQL, and Node.js/npm (Node 18+ recommended)
* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://phoenix.hexdocs.pm/deployment.html).

## Frontend

The application uses Bootstrap **6.0.0-alpha.1**, pinned in `assets/package.json`
and `assets/package-lock.json`. It requires Chrome/Edge 130+, Firefox 132+, or
Safari 18+. Bootstrap 6 is an alpha; review its migration notes before upgrading.

`mix assets.setup` installs npm dependencies with `npm ci` and installs esbuild.
`mix assets.build` compiles Phoenix colocated assets, JavaScript, and CSS, and
copies image sources into the public directory. `mix phx.server` watches both
bundles and the image sources during development.

For CI and release builds, install npm dependencies before building:

```sh
mix deps.get
mix assets.setup
MIX_ENV=prod mix assets.deploy
```

The only application bundles are `/assets/js/app.js` and `/assets/css/app.css`.
Bootstrap's compiled CSS is imported from `assets/css/app.css`; application CSS
overrides its tokens without a Sass pipeline. Colocated CSS and hooks remain
supported. Import optional Bootstrap JavaScript plugins through `app.js` when
needed; initialize stateful plugins using LiveView hooks and dispose them in
`destroyed`.

Use the shared `<.input>`, `<.button>`, `<.table>`, and `<.icon>` components.
`<.icon>` temporarily displays a local Bootstrap logo for every name, including
the `hero-*` names used by Phoenix generators. Give functional buttons visible
labels or `aria-label`. The SVG license is in
`assets/images/BOOTSTRAP-LICENSE.txt`.

All image sources, including SVG, raster images, and favicon files, belong in
`assets/images/`. The image step in `assets.build` and `assets.deploy` mirrors
this directory into `priv/static/images/`, preserving filenames and subdirectories.
That public directory is generated and ignored by Git; edit only the sources.
Use `/images/...` URLs in templates and CSS. In production, `phx.digest` runs
after the image step to generate fingerprinted and compressed copies. During
development, the image watcher also handles additions, changes, and deletions.

The theme switcher supports system, light, and dark modes. It preserves the
original `phx:theme` localStorage preference and mirrors it to an `excloud_theme`
cookie so subsequent requests render the right theme before JavaScript runs.
An existing localStorage-only preference is migrated on the first page load.
System mode uses Bootstrap's native `color-scheme` support.

## Generating pages

Local overrides in `priv/templates/` adapt HTML, LiveView, and authentication
pages to the shared Bootstrap components. Use the normal `mix phx.gen.html` and
`mix phx.gen.live` commands. For authentication, use:

```sh
mix excloud.gen.auth Accounts User users --live
# Or use --no-live for controller-based authentication.
```

This wrapper delegates to Phoenix and also converts its hardcoded injected
navigation menu, which cannot be overridden with an EEx template. It does not
change authentication logic. Follow the generated routing instructions and keep
these overrides aligned with Phoenix when upgrading dependencies.

## Checks

Run `mix precommit` for compilation, formatting, Elixir tests, and theme tests.
Run `mix assets.build` and `mix assets.deploy` to verify both asset profiles and
the digested production output.

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://phoenix.hexdocs.pm/overview.html
* Docs: https://phoenix.hexdocs.pm
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
