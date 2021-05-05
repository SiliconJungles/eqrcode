defmodule EQRCode.SVGTest do
  use ExUnit.Case

  defp content, do: "www.google.com"
  defp html_path, do: Path.expand("./test/html")

  setup do
    html_path() |> File.mkdir_p!()
    qr = content() |> EQRCode.encode()
    [qr: qr]
  end

  test "Generate an html page with different types of SVG images", %{qr: qr} do
    color = "blue"
    background_color = "yellow"

    svgs =
      []
      ## Test default option
      |> build_svgs(qr, "Default", [])
      ## Test foreground color being set
      |> build_svgs(qr, "Foreground", color: color)
      ## Test background being set
      |> build_svgs(qr, "Background", background_color: background_color)
      ## Test both background and foreground color being set
      |> build_svgs(qr, "Both Colors", background_color: background_color, color: color)
      ## Test transparency in HTML
      |> build_svgs(qr, "Transparent", background_color: :transparent, color: color)
      ## Test ViewBox
      |> build_svgs(qr, "ViewBox", background_color: background_color, color: color, viewbox: true)
      ## Test transparent viewbox in HTML
      |> build_svgs(qr, "Transparent ViewBox",
        background_color: :transparent,
        color: color,
        viewbox: true
      )

    html = gen_html(svgs)

    html_path()
    |> Path.join("svg_test.html")
    |> File.write(html)
  end

  defp build_svgs(svgs, qr, label, opts) do
    svg = EQRCode.svg(qr, opts)
    svg_c = EQRCode.svg(qr, [shape: "circle"] ++ opts)
    svgs ++ [{label, svg <> svg_c}]
  end

  defp gen_html(kw_svg) when is_list(kw_svg) do
    svg = Enum.map(kw_svg, fn {key, value} -> "<p><strong>#{key}:</strong></p>" <> value end)

    """
    <!DOCTYPE html>
    <html>
      <head>
        <title>EQRCode SVG Image Tests</title>
        <style>
          body { background: rgba(0, 255, 0); }
        </style>
      </head>
      <body>
        #{svg}
      </body>
    <html>
    """
  end
end
