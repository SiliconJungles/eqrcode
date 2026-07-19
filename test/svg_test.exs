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
      |> build_svgs(qr, "ViewBox",
        background_color: background_color,
        color: color,
        viewbox: true
      )
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

  test "embeds an image in the centre of the SVG QR code", %{qr: qr} do
    matrix_size = EQRCode.Matrix.size(qr)

    # 1. Test image with default size (15%)
    svg1 = EQRCode.svg(qr, image: "logo.png")
    assert svg1 =~ ~s(<image href="logo.png")

    p = 0.15
    w = round_to_odd(matrix_size * p)
    x = (matrix_size - w) / 2
    assert svg1 =~ ~s(width="#{w}" height="#{w}")
    assert svg1 =~ ~s(x="#{x}" y="#{x}")
    assert svg1 =~ ~s(<rect x="#{x}" y="#{x}" width="#{w}" height="#{w}" fill="#FFF"/>)

    # 2. Test inner_image and inner_image_size (using percentage 20)
    svg2 = EQRCode.svg(qr, inner_image: "custom.svg", inner_image_size: 0.20)
    assert svg2 =~ ~s(<image href="custom.svg")

    p2 = 0.20
    w2 = round_to_odd(matrix_size * p2)
    x2 = (matrix_size - w2) / 2
    assert svg2 =~ ~s(width="#{w2}" height="#{w2}")
    assert svg2 =~ ~s(x="#{x2}" y="#{x2}")
    assert svg2 =~ ~s(<rect x="#{x2}" y="#{x2}" width="#{w2}" height="#{w2}" fill="#FFF"/>)

    # 3. Test background transparent disables the background rect under the image
    svg3 = EQRCode.svg(qr, image: "logo.png", background_color: :transparent)
    refute svg3 =~ ~s(<rect x="#{x}" y="#{x}" width="#{w}" height="#{w}")
    assert svg3 =~ ~s(<image href="logo.png")

    # 4. Test image with padding option
    svg4 = EQRCode.svg(qr, image: "logo.png", inner_image_padding: 0.02)
    assert svg4 =~ ~s(<image href="logo.png")
    padding_blocks = ceil(matrix_size * 0.02)
    bg_w = w + padding_blocks * 2
    bg_x = (matrix_size - bg_w) / 2
    assert svg4 =~ ~s(<rect x="#{bg_x}" y="#{bg_x}" width="#{bg_w}" height="#{bg_w}" fill="#FFF"/>)

    # 5. Test image with align_to_grid: false
    svg5 = EQRCode.svg(qr, image: "logo.png", inner_image_padding: 0.02, align_to_grid: false)
    assert svg5 =~ ~s(<image href="logo.png")
    w_raw = matrix_size * 0.15
    bg_w_raw = w_raw + (matrix_size * 0.02 * 2)
    bg_x_raw = (matrix_size - bg_w_raw) / 2
    assert svg5 =~ ~s(width="#{w_raw}" height="#{w_raw}")
    assert svg5 =~ ~s(<rect x="#{bg_x_raw}" y="#{bg_x_raw}" width="#{bg_w_raw}" height="#{bg_w_raw}" fill="#FFF"/>)
  end

  defp round_to_odd(value) do
    r = round(value)
    r = if rem(r, 2) == 0 do
      if value > r, do: r + 1, else: r - 1
    else
      r
    end
    max(r, 1)
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
