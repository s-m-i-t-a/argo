defmodule Argo.View do
  @moduledoc """
  A view helper module.
  """

  alias ExMaybe, as: Maybe
  alias Plug.Conn

  require Logger

  defmacro __using__(opts) do
    template_root = Path.relative_to_cwd(opts[:template_root])
    templates = load_templates(template_root)

    quote bind_quoted: [template_root: template_root], unquote: true do
      @templates unquote(Macro.escape(templates))

      for {file, _} <- @templates do
        @external_resource Path.join(template_root, file <> ".eex")
      end

      def render_template(template, assigns)
          when is_binary(template) and is_list(assigns) do
        @templates
        |> Map.get(template, nil)
        |> Maybe.map(&EEx.eval_string(&1, assigns))
      end
    end
  end

  def render(%Conn{private: %{pages_render: {template, assigns}}} = conn, view_module)
      when is_binary(template) and is_list(assigns) and is_atom(view_module) do
    view_module
    |> apply(:render_template, [template, Keyword.put(assigns, :conn, conn)])
    |> log_error(template)
    |> response(conn)
  end

  defp log_error(nil, template) do
    Logger.error(fn -> "Template '#{template}' not found" end)
    nil
  end

  defp log_error(maybe, _) do
    maybe
  end

  defp response(nil, conn) do
    conn
    |> Conn.put_resp_header("content-type", "text/html")
    |> Conn.resp(500, "Internal server error")
  end

  defp response(content, conn) do
    conn
    |> Conn.put_resp_header("content-type", "text/html")
    |> Conn.resp(conn.status || 200, content)
  end

  defp load_templates(path) do
    basename = Path.expand(path)

    basename
    |> Path.join("**/*.eex")
    |> Path.wildcard()
    |> Enum.map(fn file -> {file |> Path.relative_to(basename) |> Path.rootname(), file} end)
    |> Enum.reduce(%{}, fn {key, file}, acc ->
      Map.put(acc, key, File.read!(file))
    end)
  end
end
