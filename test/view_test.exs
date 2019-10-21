defmodule ViewTest do
  @moduledoc false
  use ExUnit.Case
  use Plug.Test
  doctest Argo.View

  alias Plug.Conn
  alias Argo.View

  import ExUnit.CaptureLog

  defmodule TestView do
    use Argo.View, template_root: "test/templates"
  end

  test "should load templates from subdirectories" do
    rv = TestView.render_template("one/test.html", [])

    assert rv =~ ~r/<h1>One<\/h1>/
  end

  test "should return nil if template not found" do
    assert_raise Argo.Template.UndefinedError, fn ->
      TestView.render_template("non_exists.html", [])
    end
  end

  test "should return 500 status code if template not found" do
    rv =
      :get
      |> conn("/")
      |> Conn.put_private(:pages_render, {"non_exists.html", []})
      |> View.render(TestView)

    assert rv.status == 500
    assert rv.resp_body =~ ~r/Internal server error/
  end

  test "should return rendered template" do
    rv =
      :get
      |> conn("/")
      |> Conn.put_private(:pages_render, {"two/main.html", []})
      |> View.render(TestView)

    assert rv.status == 200
    assert rv.resp_body =~ ~r/<h1>Two<\/h1>/
  end

  test "should log error from right template" do
    assert capture_log(fn ->
             rv =
               :get
               |> conn("/")
               |> Conn.put_private(:pages_render, {"nested.html", []})
               |> View.render(TestView)

             assert rv.status == 500
             assert rv.resp_body =~ ~r/Internal server error/
           end) =~ ~r/non_exists.html/
  end
end
