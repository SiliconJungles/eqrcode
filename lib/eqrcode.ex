defmodule EQRCode do
  @moduledoc """
  Simple QR Code Generator written in Elixir with no other dependencies.

  To generate the SVG QR code:

  ```elixir
  qr_code_content = "your_qr_code_content"

  qr_code_content
  |> EQRCode.encode()
  |> EQRCode.svg()
  ```
  """

  @doc """
  Encode the binary.
  """
  @spec encode(binary) :: EQRCode.Matrix.t()
  def encode(bin) when byte_size(bin) <= 154 do
    data =
      EQRCode.Encode.encode(bin)
      |> EQRCode.ReedSolomon.encode()

    EQRCode.Encode.version(bin)
    |> EQRCode.Matrix.new()
    |> EQRCode.Matrix.draw_finder_patterns()
    |> EQRCode.Matrix.draw_seperators()
    |> EQRCode.Matrix.draw_alignment_patterns()
    |> EQRCode.Matrix.draw_timing_patterns()
    |> EQRCode.Matrix.draw_dark_module()
    |> EQRCode.Matrix.draw_reserved_format_areas()
    |> EQRCode.Matrix.draw_reserved_version_areas()
    |> EQRCode.Matrix.draw_data_with_mask(data)
    |> EQRCode.Matrix.draw_format_areas()
    |> EQRCode.Matrix.draw_version_areas()
    |> EQRCode.Matrix.draw_quite_zone()
  end

  def encode(bin) when is_nil(bin) do
    raise(ArgumentError, message: "you must pass in some input")
  end

  def encode(_),
    do: raise(ArgumentError, message: "your input is too long. keep it under 155 characters")

  @doc """
  Encode the binary with custom pattern bits. Only supports version 5.
  """
  @spec encode(binary, bitstring) :: EQRCode.Matrix.t()
  def encode(bin, bits) when byte_size(bin) <= 106 do
    data =
      EQRCode.Encode.encode(bin, bits)
      |> EQRCode.ReedSolomon.encode()

    EQRCode.Matrix.new(5)
    |> EQRCode.Matrix.draw_finder_patterns()
    |> EQRCode.Matrix.draw_seperators()
    |> EQRCode.Matrix.draw_alignment_patterns()
    |> EQRCode.Matrix.draw_timing_patterns()
    |> EQRCode.Matrix.draw_dark_module()
    |> EQRCode.Matrix.draw_reserved_format_areas()
    |> EQRCode.Matrix.draw_data_with_mask0(data)
    |> EQRCode.Matrix.draw_format_areas()
    |> EQRCode.Matrix.draw_quite_zone()
  end

  def encode(_, _), do: IO.puts("Binary too long.")

  @doc """
  ```elixir
  qr_code_content
  |> EQRCode.encode()
  |> EQRCode.svg(%{color: "#cc6600", shape: "circle", width: 300})
  ```

  You can specify the following attributes of the QR code:

  * `color`: In hexadecimal format. The default is `#000`
  * `shape`: Only `square` or `circle`. The default is `square`
  * `width`: The width of the QR code in pixel. Without the width attribute, the QR code size will be dynamically generated based on the input string.

  Default options are `%{color: "#000", shape: "square"}`.
  """
  defdelegate svg(matrix, options \\ %{}), to: EQRCode.Svg
end
