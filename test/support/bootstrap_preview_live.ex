defmodule ExcloudWeb.BootstrapPreviewLive do
  @moduledoc false
  use ExcloudWeb, :live_view

  @types %{email: :string, accepted: :boolean, role: :string, notes: :string}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(changeset(%{}), as: :preview))
     |> stream(:records, [%{id: 1, name: "First record"}])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.form for={@form} id="preview-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} type="email" label="Email" aria-describedby="email-help" />
        <p id="email-help">Your contact email</p>
        <.input field={@form[:accepted]} type="checkbox" label="Accept terms" />
        <.input
          field={@form[:role]}
          type="select"
          label="Role"
          options={[Reader: "reader", Editor: "editor"]}
        />
        <.input field={@form[:notes]} type="textarea" label="Notes" />
        <.button id="preview-save" type="submit" variant="primary" phx-disable-with="Saving…">Save</.button>
        <.button id="preview-home" navigate="/">Home</.button>
      </.form>
      <.input id="disabled-check" name="disabled_check" type="checkbox" label="Disabled" disabled />
      <.input id="custom-input" name="custom" class="custom-control" value="custom value" />
      <.input id="hidden-input" name="hidden" type="hidden" value="token" />
      <.input
        id="multiple-input"
        name="roles[]"
        type="select"
        multiple
        value={["editor"]}
        options={[Reader: "reader", Editor: "editor"]}
      />
      <.button id="preview-add" type="button" phx-click="add">Add row</.button>
      <.table id="preview-records" rows={@streams.records}>
        <:col :let={{_id, record}} label="Name">{record.name}</:col>
        <:action :let={{_id, record}}>
          <button id={"remove-#{record.id}"} phx-click="remove" phx-value-id={record.id}>Remove</button>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("validate", %{"preview" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(changeset(params), as: :preview, action: :validate))}
  end

  def handle_event("save", %{"preview" => params}, socket) do
    case Ecto.Changeset.apply_action(changeset(params), :insert) do
      {:ok, _data} -> {:noreply, put_flash(socket, :info, "Saved successfully")}
      {:error, changeset} -> {:noreply, assign(socket, :form, to_form(changeset, as: :preview))}
    end
  end

  def handle_event("add", _params, socket) do
    {:noreply, stream_insert(socket, :records, %{id: 2, name: "Second record"})}
  end

  def handle_event("remove", %{"id" => id}, socket) do
    {:noreply, stream_delete(socket, :records, %{id: String.to_integer(id)})}
  end

  defp changeset(params) do
    {%{email: nil, accepted: false, role: "reader", notes: ""}, @types}
    |> Ecto.Changeset.cast(params, Map.keys(@types))
    |> Ecto.Changeset.validate_required([:email])
    |> Ecto.Changeset.validate_format(:email, ~r/@/)
    |> Ecto.Changeset.validate_acceptance(:accepted)
  end
end
