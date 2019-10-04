defmodule Argo.ErrorController do
  @moduledoc """
  A base error controller.
  """

  use Argo.Controller

  @spec error(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def error(%Conn{} = conn, _params) do
    conn
    |> Conn.put_status(404)
    |> render("404.html")
  end
end
