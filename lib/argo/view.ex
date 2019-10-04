defmodule Argo.View do
  @moduledoc """
  A view helper module.
  """

  alias Plug.Conn

  defmacro __using__(opts) do
    template_root = Path.relative_to_cwd(opts[:template_root])
    templates = load_templates(template_root)

    quote bind_quoted: [template_root: template_root], unquote: true do
      @templates unquote(Macro.escape(templates))

      for {file, _} <- @templates do
        @external_resource Path.join(template_root, file <> ".eex")
      end

      def render_template(template, assigns) do
        @templates
        |> Map.get(template, nil)
        |> EEx.eval_string(assigns)
      end
    end
  end

  def render(%Conn{private: %{pages_render: {template, assigns}}} = conn, view_module) do
    content = apply(view_module, :render_template, [template, Keyword.put(assigns, :conn, conn)])

    conn
    |> Conn.put_resp_header("content-type", "text/html")
    |> Conn.resp(conn.status || 200, content)
  end

  defp load_templates(path) do
    path
    |> File.ls!()
    |> Enum.map(fn file -> {Path.rootname(file), Path.extname(file)} end)
    |> Enum.filter(fn {_, ext} -> ext == ".eex" end)
    |> Enum.reduce(%{}, fn {k, ext}, acc ->
      Map.put(acc, k, path |> Path.join(k <> ext) |> File.read!())
    end)
  end
end
