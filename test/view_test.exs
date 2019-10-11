defmodule ViewTest do
  @moduledoc false
  use ExUnit.Case
  doctest Argo.View

  # alias Argo.View

  defmodule TestView do
    use Argo.View, template_root: "test/templates"
  end

  test "should load templates from subdirectories" do
    rv = TestView.render_template("one/test.html", [])

    assert rv =~ ~r/<h1>One<\/h1>/
  end
end
