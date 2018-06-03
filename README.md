# Eqrcode

Simple QR Code Generator written in Elixir with no other dependencies.

To generate the SVG QR code:

```elixir
qr_code_content = "your_qr_code_content"

qr_code_content
|> EQRCode.encode()
|> EQRCode.svg()
```

### Options

You can also pass in options into `EQRCode.svg()`:

```elixir
qr_code_content
|> EQRCode.encode()
|> EQRCode.svg(%{color: "#cc6600", shape: "circle"})
```

For now, you can specify the color of the QR code in hexadecimal format, or the shape of each individual pixel. We only allow either square or circle for the shape option.

Default options are `%{color: "#000", shape: "square"}`.

## Installation (pending)

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `eqrcode` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:eqrcode, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/eqrcode](https://hexdocs.pm/eqrcode).

## Credits

We reused most of the code from [sunboshan/qrcode](https://github.com/sunboshan/qrcode) to generate the matrix required to render the QR Code. We also reference [rqrcode](https://github.com/whomwah/rqrcode) on how to generate SVG from the QR Code matrix.
