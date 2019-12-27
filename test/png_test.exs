defmodule EQRCode.PNGTest do
  use ExUnit.Case

  defp content, do: "www.google.com"
  defp html_path, do: Path.expand("./test/html")
  defp image_path, do: Path.expand("./test/images")

  setup do
    html_path() |> File.mkdir_p!()
    image_path() |> File.mkdir_p!()
    qr = content() |> EQRCode.encode()
    [qr: qr]
  end

  test "Generate an html page with different types of PNG images", %{qr: qr} do
    color = <<0, 0, 255>>
    background_color = <<255, 255, 0>>

    pngs =
      []
      ## Test Default
      |> build_png(qr, "Default", [])
      ## Test Foreground Color png
      |> build_png(qr, "Foreground", color: color)
      ## Test Background Color png
      |> build_png(qr, "Background", background_color: background_color)
      ## Test Foreground and Background Color
      |> build_png(qr, "Both Colors", background_color: background_color, color: color)
      ## Test Background Transparency
      |> build_png(qr, "Transparent", background_color: :transparent, color: color)

    html = gen_html(pngs)

    html_path()
    |> Path.join("png_test.html")
    |> File.write(html)
  end

  defp write_png_to_file(png_binary, path), do: File.write!(path, png_binary, [:binary])

  defp build_png(png_list, qr, label, opts) do
    png_path = image_path() |> Path.join(Macro.underscore(label) <> ".png")

    EQRCode.png(qr, opts)
    |> write_png_to_file(png_path)

    png_relative_path = "../images/" <> Path.basename(png_path)
    png_list ++ [{label, png_relative_path}]
  end

  defp gen_html(kw_png) when is_list(kw_png) do
    png =
      Enum.map(kw_png, fn {key, value} ->
        ~s{<p><strong>#{key}:</strong></p><img src="#{value}">}
      end)

    """
    <!DOCTYPE html>
    <html>
      <head>
        <title>EQRCode PNG Image Tests</title>
        <style>
          body { background: rgba(0, 255, 0); }
        </style>
      </head>
      <body>
        #{png}
      </body>
    </html>
    """
  end
end
