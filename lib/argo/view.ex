defmodule Argo.View do
  @moduledoc """
  A view helper module.
  """

  alias Plug.Conn

  def render(%Conn{private: %{pages_render: {template, assigns}}} = conn, templates_path) do
    content =
      templates_path
      |> Path.join("#{template}.eex")
      |> EEx.eval_file(Keyword.put(assigns, :conn, conn))

    Conn.resp(conn, 200, content)
  end
end
