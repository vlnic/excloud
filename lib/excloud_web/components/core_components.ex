defmodule ExcloudWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  Styled with Bootstrap 6. Keep form, navigation, stream and flash behavior
  in these components so templates share a consistent public API.

  Icons temporarily render the local Bootstrap logo through `icon/1`.
  """

  use Gettext, backend: ExcloudWeb.Gettext
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash
        id="welcome-back"
        kind={:info}
        phx-mounted={show("#welcome-back") |> JS.remove_attribute("hidden")}
        hidden
      >
        Welcome Back!
      </.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      role="alert"
      class={["alert app-flash", if(@kind == :info, do: "theme-info", else: "theme-danger")]}
      {@rest}
    >
      <.icon name={if(@kind == :info, do: "hero-information-circle", else: "hero-exclamation-circle")} />
      <div class="flex-grow-1">
        <p :if={@title} class="fw-semibold mb-1">{@title}</p>
        <p class="mb-0">{msg}</p>
      </div>
      <button
        id={"#{@id}-dismiss"}
        type="button"
        class="btn-text btn-icon"
        aria-label={gettext("close")}
        phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      >
        <.icon name="hero-x-mark" />
      </button>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global,
    include: ~w(href navigate patch method download name value disabled type form)

  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-solid theme-primary", nil => "btn-subtle theme-primary"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["app-button", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://phoenix-html.hexdocs.pm/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(assigns) do
    error_id = if assigns.id && assigns.errors != [], do: "#{assigns.id}-errors"

    description_ids = [assigns.rest[:"aria-describedby"], error_id]

    described_by =
      description_ids
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")

    assigns =
      assigns
      |> assign(:error_id, error_id)
      |> assign(:described_by, if(described_by == "", do: nil, else: described_by))
      |> assign(
        :invalid,
        if(assigns.errors != [], do: "true", else: assigns.rest[:"aria-invalid"])
      )
      |> assign(:rest, Map.drop(assigns.rest, [:"aria-describedby", :"aria-invalid"]))
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <%= case @type do %>
      <% "hidden" -> %>
        <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
      <% "checkbox" -> %>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <div class="form-field mb-4">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={[@class || "check", @errors != [] && (@error_class || "is-invalid")]}
            aria-invalid={@invalid}
            aria-describedby={@described_by}
            {@rest}
          />
          <div class="form-field-content">
            <label :if={@label} for={@id}>{@label}</label>
            <.field_errors id={@error_id} errors={@errors} />
          </div>
        </div>
      <% _ -> %>
        <div class="form-field mb-4">
          <label :if={@label} for={@id} class="form-label">{@label}</label>
          <%= case @type do %>
            <% "select" -> %>
              <select
                id={@id}
                name={@name}
                class={[@class || "form-control", @errors != [] && (@error_class || "is-invalid")]}
                multiple={@multiple}
                aria-invalid={@invalid}
                aria-describedby={@described_by}
                {@rest}
              >
                <option :if={@prompt} value="">{@prompt}</option>
                {Phoenix.HTML.Form.options_for_select(@options, @value)}
              </select>
            <% "textarea" -> %>
              <textarea
                id={@id}
                name={@name}
                class={[@class || "form-control", @errors != [] && (@error_class || "is-invalid")]}
                aria-invalid={@invalid}
                aria-describedby={@described_by}
                {@rest}
              >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
            <% _ -> %>
              <input
                type={@type}
                name={@name}
                id={@id}
                value={Phoenix.HTML.Form.normalize_value(@type, @value)}
                class={[@class || "form-control", @errors != [] && (@error_class || "is-invalid")]}
                aria-invalid={@invalid}
                aria-describedby={@described_by}
                {@rest}
              />
          <% end %>
          <.field_errors id={@error_id} errors={@errors} />
        </div>
    <% end %>
    """
  end

  attr :id, :string, default: nil
  attr :errors, :list, required: true

  defp field_errors(assigns) do
    ~H"""
    <div :if={@errors != []} id={@id} class="invalid-feedback d-block">
      <p :for={msg <- @errors} class="mb-0">{msg}</p>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[
      @actions != [] && "d-flex flex-wrap align-items-center justify-content-between gap-4",
      "mb-5"
    ]}>
      <div>
        <h1 class="h3 fw-semibold mb-2">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="app-muted mb-0">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="d-flex flex-wrap gap-2">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="table-responsive">
      <table class="table table-striped align-middle">
        <thead>
          <tr>
            <th :for={col <- @col}>{col[:label]}</th>
            <th :if={@action != []}>
              <span class="visually-hidden">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={@row_click && "app-clickable"}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="app-table-actions fw-semibold">
              <div class="d-flex gap-3">
                <%= for action <- @action do %>
                  {render_slot(action, @row_item.(row))}
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <dl class="app-detail-list">
      <div :for={item <- @item} class="row py-3 border-bottom">
        <dt class="sm:col-4 fw-semibold">{item.title}</dt>
        <dd class="sm:col-8 mb-0">{render_slot(item)}</dd>
      </div>
    </dl>
    """
  end

  @doc """
  Renders the local Bootstrap logo as a temporary icon.

  The name parameter remains compatible with generated Phoenix templates.
  Functional buttons must provide a visible label or aria-label.
  """
  attr :name, :string, required: true
  attr :class, :any, default: nil

  def icon(assigns) do
    ~H"""
    <svg
      class={["app-icon", @class]}
      viewBox="0 0 16 16"
      fill="currentColor"
      aria-hidden="true"
      focusable="false"
    >
      <use href="/images/bootstrap.svg#bootstrap-mark" />
    </svg>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition: {"app-enter", "app-transition-hidden", "app-transition-visible"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition: {"app-leave", "app-transition-visible", "app-transition-hidden"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ExcloudWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ExcloudWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
