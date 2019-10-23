defmodule RouterTest do
  @moduledoc false
  use ExUnit.Case
  use Plug.Test

  doctest Argo.Router

  alias Argo.Router

  defmodule TestController do
    use Argo.Controller

    def index(conn, _) do
      render(conn, "one/test.html")
    end
  end

  defmodule TestView do
    use Argo.View, template_root: "test/templates"
  end

  defmodule TestErrorView do
    use Argo.View, template_root: "test/templates/errors"
  end

  defmodule TestRouter do
    use Argo.Router

    Router.get("/", TestController, :index)
  end

  test "should render 404 when route not found" do
    defaults = TestRouter.init([])

    rv =
      :get
      |> conn("/non_exists")
      |> TestRouter.call(defaults)

    assert rv.status == 404
    assert rv.resp_body =~ ~r/ERROR/
  end
end
