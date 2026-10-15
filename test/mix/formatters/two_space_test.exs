defmodule Mix.Formatters.TwoSpaceTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Mix.Formatters.TwoSpace

  test "multiline assertions keep two-space continuation indentation" do
    source = """
    def check(view) do
      assert has_element?(
        view,
        "#preview_accepted.check.is-invalid[aria-describedby='preview_accepted-errors']"
      )
    end
    """

    aligned = source |> Code.format_string!() |> IO.iodata_to_binary()

    assert TwoSpace.format(aligned, []) == source
    assert TwoSpace.format(TwoSpace.format(source, []), []) == source
  end

  test "formatting preserves comments and the meaning of strings and expressions" do
    source = ~S'''
    # Keep this comment.
    def check(view) do
      assert has_element?(
        view,
        "#selector[data-value='\t']"
      )

      text = """
        A deliberately indented line.
      """

      {text, ~r/\s+/, %{path: "line\nnext"}}
    end
    '''

    formatted = TwoSpace.format(source, [])

    assert syntax(formatted) == syntax(source)
    assert String.starts_with?(formatted, "# Keep this comment.\n")
    assert TwoSpace.format(formatted, []) == formatted
  end

  test "empty files stay empty" do
    assert TwoSpace.format("", []) == ""
  end

  defp syntax(source) do
    quoted = Code.string_to_quoted!(source)

    Macro.prewalk(quoted, fn
      {name, metadata, arguments} when is_list(metadata) -> {name, [], arguments}
      node -> node
    end)
  end
end
