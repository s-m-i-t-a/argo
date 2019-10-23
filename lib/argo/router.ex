defmodule Argo.Router do
  alias Argo.{Controller, View}

  alias Plug.Conn

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :routes, accumulate: true, persist: false)

      @before_compile unquote(__MODULE__)

      alias Argo.Router

      use Plug.Router
    end
  end

  defmacro __before_compile__(env) do
    compile(Module.get_attribute(env.module, :routes))
  end

  defmacro get(path, module, function) do
    quote bind_quoted: [path: path, module: module, function: function] do
      @routes {:get, path, module, function}
    end
  end

  defmacro post(path, module, function) do
    quote bind_quoted: [path: path, module: module, function: function] do
      @routes {:post, path, module, function}
    end
  end

  defmacro put(path, module, function) do
    quote bind_quoted: [path: path, module: module, function: function] do
      @routes {:put, path, module, function}
    end
  end

  defmacro patch(path, module, function) do
    quote bind_quoted: [path: path, module: module, function: function] do
      @routes {:patch, path, module, function}
    end
  end

  defmacro delete(path, module, function) do
    quote bind_quoted: [path: path, module: module, function: function] do
      @routes {:delete, path, module, function}
    end
  end

  defmacro options(path, module, function) do
    quote bind_quoted: [path: path, module: module, function: function] do
      @routes {:options, path, module, function}
    end
  end

  def compile(routes) do
    routes_ast =
      for {method, path, module, function} <- routes do
        defroute(method, path, module, function)
      end

    final_ast =
      quote do
        plug(:match)
        plug(:dispatch)
        unquote(routes_ast)

        match _ do
          Argo.Router.process_error(var!(conn), __MODULE__)
        end
      end

    final_ast
  end

  def process_error(conn, module) do
    conn
    |> Controller.call(Argo.ErrorController, :error)
    |> View.render(error_view_name_from_router(module))
    |> Conn.send_resp()
  end

  def process(conn, module, function) do
    conn
    |> Controller.call(module, function)
    |> View.render(view_name_from_controller(module))
    |> Conn.send_resp()
  end

  defp defroute(:get, path, module, function) do
    quote do
      get unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  defp defroute(:post, path, module, function) do
    quote do
      post unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  defp defroute(:put, path, module, function) do
    quote do
      put unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  defp defroute(:patch, path, module, function) do
    quote do
      patch unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  defp defroute(:delete, path, module, function) do
    quote do
      delete unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
  end

  defp defroute(:options, path, module, function) do
    quote do
      options unquote(path) do
        Argo.Router.process(var!(conn), unquote(module), unquote(function))
      end
    end
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

  defp error_view_name_from_router(router_name) when is_atom(router_name) do
    router_name
    |> unsuffix("Router")
    |> Kernel.<>("ErrorView")
    |> String.to_existing_atom()
  end
end
