defmodule Mix.Formatters.TwoSpace do
  @moduledoc """
  Keeps Elixir formatting while limiting continuation indentation to two spaces.

  Replaces column alignment in the formatter's document model rather than
  rewriting source text, so strings, comments, and sigils retain their contents.
  """

  @behaviour Mix.Tasks.Format

  @impl true
  def features(_options) do
    [extensions: [".ex", ".exs"]]
  end

  @impl true
  def format(source, options) do
    parser_options =
      Keyword.merge(options,
        unescape: false,
        literal_encoder: &{:ok, {:__block__, &2, [&1]}},
        token_metadata: true,
        emit_warnings: false
      )

    {quoted, comments} = Code.string_to_quoted_with_comments!(source, parser_options)
    algebra_options = Keyword.merge(options, comments: comments, escape: false)
    document = Code.quoted_to_algebra(quoted, algebra_options)
    line_length = Keyword.get(options, :line_length, 98)

    formatted =
      document
      |> limit_indentation()
      |> Inspect.Algebra.format(line_length)

    case formatted do
      [] -> ""
      contents -> IO.iodata_to_binary([contents, ?\n])
    end
  end

  defp limit_indentation({:doc_nest, document, :cursor, mode}) do
    {:doc_nest, limit_indentation(document), 0, mode}
  end

  defp limit_indentation({:doc_nest, document, level, mode}) when is_integer(level) do
    {:doc_nest, limit_indentation(document), min(level, 2), mode}
  end

  defp limit_indentation(document) when is_tuple(document) do
    document
    |> Tuple.to_list()
    |> Enum.map(&limit_indentation/1)
    |> List.to_tuple()
  end

  defp limit_indentation(document) when is_list(document) do
    Enum.map(document, &limit_indentation/1)
  end

  defp limit_indentation(document) do
    document
  end
end
