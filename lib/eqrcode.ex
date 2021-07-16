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

  alias EQRCode.{Encode, ReedSolomon, Matrix}

  @type error_correction_level :: :l | :m | :q | :h

  @doc """
  Encode the binary.
  """
  @spec encode(binary, error_correction_level(), atom()) :: Matrix.t()
  def encode(bin, error_correction_level \\ :l, mode \\ :byte)

  def encode(bin, error_correction_level, mode) when byte_size(bin) <= 2952 do
    {version, error_correction_level, data} =
      Encode.encode(bin, error_correction_level, mode)
      |> ReedSolomon.encode()

    Matrix.new(version, error_correction_level)
    |> Matrix.draw_finder_patterns()
    |> Matrix.draw_seperators()
    |> Matrix.draw_alignment_patterns()
    |> Matrix.draw_timing_patterns()
    |> Matrix.draw_dark_module()
    |> Matrix.draw_reserved_format_areas()
    |> Matrix.draw_reserved_version_areas()
    |> Matrix.draw_data_with_mask(data)
    |> Matrix.draw_format_areas()
    |> Matrix.draw_version_areas()
    |> Matrix.draw_quite_zone()
  end

  def encode(bin, _error_correction_level, _mode) when is_nil(bin) do
    raise(ArgumentError, message: "you must pass in some input")
  end

  def encode(_, _, _),
    do: raise(ArgumentError, message: "your input is too long. keep it under 2952 characters")

  @doc """
  Encode the binary with custom pattern bits. Only supports version 5.
  """
  @spec encode_with_pattern(binary, error_correction_level(), bitstring) :: Matrix.t()
  def encode_with_pattern(bin, error_correction_level, bits) when byte_size(bin) <= 106 do
    {version, error_correction_level, data} =
      Encode.encode(bin, error_correction_level, bits)
      |> ReedSolomon.encode()

    Matrix.new(version, error_correction_level)
    |> Matrix.draw_finder_patterns()
    |> Matrix.draw_seperators()
    |> Matrix.draw_alignment_patterns()
    |> Matrix.draw_timing_patterns()
    |> Matrix.draw_dark_module()
    |> Matrix.draw_reserved_format_areas()
    |> Matrix.draw_data_with_mask0(data)
    |> Matrix.draw_format_areas()
    |> Matrix.draw_quite_zone()
  end

  def encode_with_pattern(_, _, _), do: IO.puts("Binary too long.")

  @doc """
  ```elixir
  qr_code_content
  |> EQRCode.encode()
  |> EQRCode.svg(color: "#cc6600", shape: "circle", width: 300)
  ```

  You can specify the following attributes of the QR code:

  * `background_color`: In hexadecimal format or `:transparent`. The default is `#FFF`
  * `color`: In hexadecimal format. The default is `#000`
  * `shape`: Only `square` or `circle`. The default is `square`
  * `width`: The width of the QR code in pixel. Without the width attribute, the QR code size will be dynamically generated based on the input string.
  * `viewbox`: When set to `true`, the SVG element will specify its height and width using `viewBox`, instead of explicit `height` and `width` tags.

  Default options are `[color: "#000", shape: "square", background_color: "#FFF"]`.
  """
  defdelegate svg(matrix, options \\ []), to: EQRCode.SVG

  @doc """
  ```elixir
  qr_code_content
  |> EQRCode.encode()
  |> EQRCode.png(color: <<255, 0, 255>>, width: 200)
  ```

  You can specify the following attributes of the QR code:

  * `color`: In binary format. The default is `<<0, 0, 0>>`
  * `background_color`: In binary format or `:transparent`. The default is `<<255, 255, 255>>`
  * `width`: The width of the QR code in pixel. (the actual size may vary, due to the number of modules in the code)

  By default, QR code size will be dynamically generated based on the input string.
  """
  defdelegate png(matrix, options \\ []), to: EQRCode.PNG

  @doc """
  ```elixir
  qr_code_content
  |> EQRCode.encode()
  |> EQRCode.render()
  ```
  """
  defdelegate render(matrix), to: EQRCode.Render
end
