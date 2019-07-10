defmodule Argo.Router do
  alias Argo.{Controller, View}

  alias Plug.Conn

  defmacro __using__(_opts) do
    quote do
      use Plug.Router

      alias Argo.Router

      plug(:match)
      plug(:dispatch)
    end
  end

  defmacro get(path, module, function) do
    quote do
      get unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  defmacro post(path, module, function) do
    quote do
      post unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  defmacro put(path, module, function) do
    quote do
      put unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  defmacro patch(path, module, function) do
    quote do
      patch unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  defmacro delete(path, module, function) do
    quote do
      delete unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  defmacro options(path, module, function) do
    quote do
      options unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  def process(conn, module, function) do
    conn
    |> Controller.call(module, function)
    |> View.render(view_name_from_controller(module))
    |> Conn.send_resp()
  end

  defp view_name_from_controller(controller_name) when is_atom(controller_name) do
    controller_name
    |> unsuffix("Controller")
    |> Kernel.<>("View")
    |> String.to_existing_atom()
  end

  defp unsuffix(value, suffix) do
    string = to_string(value)
    suffix_size = byte_size(suffix)
    prefix_size = byte_size(string) - suffix_size

    case string do
      <<prefix::binary-size(prefix_size), ^suffix::binary>> -> prefix
      _ -> string
    end
  end
end
