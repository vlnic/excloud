defmodule ExcloudWeb.GeneratorFormTest do
  use ExUnit.Case, async: false
  import Phoenix.LiveViewTest

  test "the HTML generator produces an embedded form that renders changeset values" do
    directory =
      Path.join(System.tmp_dir!(), "excloud-generator-form-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(directory, "generated_resource_html"))
    on_exit(fn -> File.rm_rf!(directory) end)

    bindings = [
      context: %{web_module: ExcloudWeb},
      schema: %{
        web_namespace: nil,
        alias: GeneratedResource,
        singular: "generated_resource",
        human_singular: "Generated resource"
      },
      inputs: [~s(<.input field={f[:name]} type="text" label="Name" />)]
    ]

    for {template, output} <- [
          {"html.ex.eex", "generated_resource_html.ex"},
          {"resource_form.html.heex.eex",
           "generated_resource_html/generated_resource_form.html.heex"}
        ] do
      contents = EEx.eval_file("priv/templates/phx.gen.html/#{template}", bindings)
      File.write!(Path.join(directory, output), contents)
    end

    Code.compile_file(Path.join(directory, "generated_resource_html.ex"))
    component = Function.capture(ExcloudWeb.GeneratedResourceHTML, :generated_resource_form, 1)
    changeset = Ecto.Changeset.change({%{name: "Example"}, %{name: :string}})

    document =
      component
      |> render_component(changeset: changeset, action: "/", return_to: nil)
      |> LazyHTML.from_fragment()

    assert document |> LazyHTML.query("#generated_resource-form[action='/']") |> Enum.any?()

    assert document
           |> LazyHTML.query("#generated_resource-form input.form-control[value='Example']")
           |> Enum.any?()

    assert document
           |> LazyHTML.query("#generated_resource-form button.btn-solid.theme-primary")
           |> Enum.any?()
  end
end
