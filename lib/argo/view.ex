defmodule Argo.View do
  @moduledoc """
  A view helper module.
  """

  alias ExMaybe, as: Maybe
  alias Plug.Conn

  alias Argo.Template

  require Logger

  defmacro __using__(opts) do
    template_root = Path.relative_to_cwd(opts[:template_root])
    templates = load_templates(template_root)

    quote bind_quoted: [template_root: template_root], unquote: true do
      alias Argo.Template

      @template_root template_root
      @templates unquote(Macro.escape(templates))

      for {file, _} <- @templates do
        @external_resource Path.join(template_root, file <> ".eex")
      end

      @doc """
      Callback invoked when no template is found.
      """
      @spec template_not_found(ExMaybe.t(String.t()), String.t(), list()) :: String.t()
      def template_not_found(nil, template, assigns)
          when is_binary(template) and is_list(assigns) do
        Template.raise_template_not_found(__MODULE__, template, assigns)
      end

      def template_not_found(value, _template, _assigns) when is_binary(value) do
        value
      end

      @spec render_template(String.t(), list()) :: String.t()
      def render_template(template, assigns)
          when is_binary(template) and is_list(assigns) do
        @templates
        |> Map.get(template, nil)
        |> Maybe.map(&EEx.eval_string(&1, assigns))
        |> template_not_found(template, assigns)
      end

      def __templates__() do
        {@template_root, @templates}
      end
    end
  end

  def render(%Conn{private: %{pages_render: {template, assigns}}} = conn, view_module)
      when is_binary(template) and is_list(assigns) and is_atom(view_module) do
    content =
      try do
        apply(view_module, :render_template, [template, Keyword.put(assigns, :conn, conn)])
      rescue
        e in Template.UndefinedError ->
          Logger.error(fn -> Template.UndefinedError.message(e) end)
          nil
      end

    response(conn, content)
  end

  defp response(conn, nil) do
    conn
    |> Conn.put_resp_header("content-type", "text/html")
    |> Conn.resp(500, "Internal server error")
  end

  defp response(conn, content) do
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
