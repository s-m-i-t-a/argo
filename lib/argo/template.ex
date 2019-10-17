defmodule Argo.Template do
  @moduledoc """
  A template helpers.
  """

  defmodule UndefinedError do
    @moduledoc """
    Exception raised when a template cannot be found.
    """
    defexception [:available, :template, :module, :root, :assigns]

    def message(exception) do
      # <> "please define a matching clause for render/2 or define a template at "
      "Could not render #{inspect(exception.template)} for #{inspect(exception.module)}, " <>
        "please define a template at " <>
        "#{inspect(Path.relative_to_cwd(exception.root))}. " <>
        available_templates(exception.available) <>
        "\nAssigns:\n\n" <>
        inspect(exception.assigns) <>
        "\n\nAssigned keys: #{inspect(Keyword.keys(exception.assigns))}\n"
    end

    defp available_templates([]), do: "No templates were compiled for this module."

    defp available_templates(available) do
      "The following templates were compiled:\n\n" <>
        Enum.map_join(available, "\n", &"* #{&1}") <>
        "\n"
    end
  end

  @doc false
  def raise_template_not_found(view_module, template, assigns) do
    {root, templates} = view_module.__templates__()

    raise UndefinedError,
      assigns: assigns,
      available: Map.keys(templates),
      template: template,
      root: root,
      module: view_module
  end
end
