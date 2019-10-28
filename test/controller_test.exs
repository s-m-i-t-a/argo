defmodule ControllerTest do
  @moduledoc false
  use ExUnit.Case
  use Plug.Test
  doctest Argo.Controller

  alias Argo.Controller

  alias Plug.Conn

  defmodule TestController do
    use Argo.Controller

    def index(%Conn{} = conn, params) do
      send(self(), {:index_called, conn, params})
      conn
    end
  end

  describe "Call" do
    test "should call right function" do
      c = conn(:get, "/", %{foo: :bar})

      Controller.call(c, TestController, :index)

      assert_received {:index_called, ^c, %{"foo" => :bar}}
    end
  end

  describe "Redirect" do
    test "should use to: for local redirect" do
      conn = Controller.redirect(conn(:get, "/"), to: "/foobar")

      content_type =
        conn
        |> Conn.get_resp_header("content-type")
        |> List.first()
        |> String.split(";")
        |> Enum.fetch!(0)

      assert conn.resp_body =~ "/foobar"
      assert content_type == "text/html"
      assert Conn.get_resp_header(conn, "location") == ["/foobar"]
      refute conn.halted

      conn = Controller.redirect(conn(:get, "/"), to: "/<foobar>")
      assert conn.resp_body =~ "/&lt;foobar&gt;"

      assert_raise ArgumentError, ~r/the :to option in redirect expects a path/, fn ->
        Controller.redirect(conn(:get, "/"), to: "http://example.com")
      end

      assert_raise ArgumentError, ~r/the :to option in redirect expects a path/, fn ->
        Controller.redirect(conn(:get, "/"), to: "//example.com")
      end

      assert_raise ArgumentError, ~r/unsafe/, fn ->
        Controller.redirect(conn(:get, "/"), to: "/\\example.com")
      end
    end

    test "should use :external for extern redirect" do
      conn = Controller.redirect(conn(:get, "/"), external: "http://example.com")
      assert conn.resp_body =~ "http://example.com"
      assert Conn.get_resp_header(conn, "location") == ["http://example.com"]
      refute conn.halted
    end

    test "should keep stored status or use default" do
      conn = conn(:get, "/") |> Controller.redirect(to: "/")
      assert conn.status == 302
      conn = conn(:get, "/") |> put_status(301) |> Controller.redirect(to: "/")
      assert conn.status == 301
    end
  end

  describe "Render" do
    test "should set private value in conn with template and assigns" do
      %Conn{private: %{argo_render_template: {template, assigns}}} =
        :get
        |> conn("/")
        |> Controller.render("test.html", foo: :bar)

      assert template == "test.html"
      assert Keyword.get(assigns, :foo) == :bar
    end
  end
end
