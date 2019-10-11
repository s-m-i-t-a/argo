defmodule Argo.Controller do
  @moduledoc """
  Call selected controller with conn and params.
  """
  alias Plug.Conn

  defmacro __using__(_options) do
    quote do
      alias Plug.Conn

      import Argo.Controller
    end
  end

  def call(%Conn{} = conn, module, function) when is_atom(module) and is_atom(function) do
    apply(module, function, [conn, conn.params])
  end

  def render(%Conn{} = conn, template, assigns \\ [])
      when is_binary(template) and is_list(assigns) do
    Conn.put_private(conn, :pages_render, {template, assigns})
  end

  @spec redirect(Conn.t(), list()) :: Conn.t()
  def redirect(conn, opts) when is_list(opts) do
    url = url(opts)
    html = Plug.HTML.html_escape(url)
    body = "<html><body>You are being <a href=\"#{html}\">redirected</a>.</body></html>"

    conn
    |> Conn.put_resp_header("location", url)
    |> Conn.put_resp_header("content-type", "text/html")
    |> Conn.send_resp(conn.status || 302, body)
  end

  defp url(opts) do
    cond do
      to = opts[:to] -> validate_local_url(to)
      external = opts[:external] -> external
      true -> raise ArgumentError, "expected :to or :external option in redirect/2"
    end
  end

  @invalid_local_url_chars ["\\"]
  defp validate_local_url("//" <> _ = to), do: raise_invalid_url(to)

  defp validate_local_url("/" <> _ = to) do
    if String.contains?(to, @invalid_local_url_chars) do
      raise ArgumentError, "unsafe characters detected for local redirect in URL #{inspect(to)}"
    else
      to
    end
  end

  defp validate_local_url(to), do: raise_invalid_url(to)

  @spec raise_invalid_url(term()) :: no_return()
  defp raise_invalid_url(url) do
    raise ArgumentError, "the :to option in redirect expects a path but was #{inspect(url)}"
  end
end
