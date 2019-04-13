# EQRCode

Simple QR Code Generator written in Elixir with no other dependencies.

## Installation

```elixir
def deps do
  [
    {:eqrcode, "~> 0.1.6"}
  ]
end
```

## Using EQRCode

You can use EQRCode to generate QR Code in SVG or PNG format.

```elixir
qr_code_content = "your_qr_code_content"

# To SVG
qr_code_content
|> EQRCode.encode()
|> EQRCode.svg()

# To PNG
qr_code_content
|> EQRCode.encode()
|> EQRCode.png()
```
<img src="./screenshots/default.png" width="300">

Note that the PNG format is only the binary. You still have to write the data to a file:

```elixir
qr_code_png =
  qr_code_content
  |> EQRCode.encode()
  |> EQRCode.png()

File.write("path/where/you/want/to/save.png", qr_code_png, [:binary])
```

You should be able to see the file generated in the path you specified.

## Image Rendering Options

### SVG

You can pass in options into `EQRCode.svg()`:

```elixir
qr_code_content
|> EQRCode.encode()
|> EQRCode.svg(color: "#03B6AD", shape: "circle", width: 300)
```

<img src="./screenshots/circle-color.png" width="300">

You can specify the following attributes of the QR code:

* `color`: In hexadecimal format. The default is `#000`
* `shape`: Only `square` or `circle`. The default is `square`
* `width`: The width of the QR code in pixel. Without the width attribute, the QR code size will be dynamically generated based on the input string.
* `viewbox`: When set to `true`, the SVG element will specify its height and width using `viewBox`, instead of explicit `height` and `width` tags.

Default options are `[color: "#000", shape: "square"]`.

### PNG

You can specify the following attributes of the QR code:

* `color`: In binary format in the RGB order. The default is `<<0, 0, 0>>`
* `width`: The width of the QR code in pixel. (the actual size may vary, due to the number of modules in the code)

By default, QR code size will be dynamically generated based on the input string.

## Credits

We reused most of the code from [sunboshan/qrcode](https://github.com/sunboshan/qrcode) to generate the matrix required to render the QR Code. We also reference [rqrcode](https://github.com/whomwah/rqrcode) on how to generate SVG from the QR Code matrix.

## License

This project is Licensed under the [MIT License](https://github.com/SiliconJungles/eqrcode/blob/master/LICENSE).
