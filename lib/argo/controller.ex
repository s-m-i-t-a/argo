defmodule Argo.Controller do
  @moduledoc """
  Call selected controller with conn and params.
  """

  alias Plug.Conn

  def call(%Conn{} = conn, module, function) do
    apply(module, function, [conn, conn.params])
  end

  def render(%Conn{} = conn, template, assigns \\ []) do
    Conn.put_private(conn, :pages_render, {template, assigns})
  end
end
