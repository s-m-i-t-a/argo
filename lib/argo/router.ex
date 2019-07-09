defmodule Argo.Router do
  alias Argo.{Controller, View}

  alias Plug.Conn

  defmacro __using__(opts) do
    quote do
      use Plug.Router

      alias Argo.Router

      @template_root Path.relative_to_cwd(unquote(opts)[:template_root])

      plug(:match)
      plug(:dispatch)
    end
  end

  defmacro get(path, module, function) do
    quote do
      get unquote(path) do
        Argo.Router.process(var!(conn), @template_root, unquote(module), unquote(function))
      end
    end
  end

  defmacro post(path, module, function) do
    quote do
      post unquote(path) do
        Argo.Router.process(var!(conn), @template_root, unquote(module), unquote(function))
      end
    end
  end

  defmacro put(path, module, function) do
    quote do
      put unquote(path) do
        Argo.Router.process(var!(conn), @template_root, unquote(module), unquote(function))
      end
    end
  end

  defmacro patch(path, module, function) do
    quote do
      patch unquote(path) do
        Argo.Router.process(var!(conn), @template_root, unquote(module), unquote(function))
      end
    end
  end

  defmacro delete(path, module, function) do
    quote do
      delete unquote(path) do
        Argo.Router.process(var!(conn), @template_root, unquote(module), unquote(function))
      end
    end
  end

  defmacro options(path, module, function) do
    quote do
      options unquote(path) do
        Argo.Router.process(var!(conn), @template_root, unquote(module), unquote(function))
      end
    end
  end

  def process(conn, template_dir, module, function) do
    conn
    |> Controller.call(module, function)
    |> View.render(template_dir)
    |> Conn.send_resp()
  end
end
