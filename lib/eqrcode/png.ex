defmodule EQRCode.PNG do
  @moduledoc """
  Render the QR Code matrix in PNG format.
  """

  alias EQRCode.Matrix

  @defaults %{
    background_color: <<255, 255, 255>>,
    color: <<0, 0, 0>>,
    module_size: 11
  }

  @transparent_alpha <<0>>
  @opaque_alpha <<255>>

  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>

  @doc """
  Returns the PNG binary representation of the QR Code

  ## Options

  You can specify the following attributes of the QR code:

  * `:color` - In binary format. The default is `<<0, 0, 0>>`

  * `:background_color` - In binary format or `:transparent`. The default is
    `<<255, 255, 255>>`

  * `:width` - The width of the QR code in pixel. (the actual size may vary, due
    to the number of modules in the code)

  By default, QR code size will be dynamically generated based on the input string.

  ## Examples

      qr_code_content
      |> EQRCode.encode()
      |> EQRCode.png(color: <<255, 0, 255>>, width: 200)

  """
  @spec png(Matrix.t(), map() | Keyword.t()) :: String.t()
  def png(%Matrix{matrix: matrix} = m, options \\ []) do
    matrix_size = Matrix.size(m)
    options = normalize_options(options, matrix_size)
    pixel_size = matrix_size * options[:module_size]

    ihdr = png_chunk("IHDR", <<pixel_size::32, pixel_size::32, 8::8, 6::8, 0::24>>)
    idat = png_chunk("IDAT", pixels(matrix, options))
    iend = png_chunk("IEND", "")

    [@png_signature, ihdr, idat, iend]
    |> List.flatten()
    |> Enum.join()
  end

  defp normalize_options(options, matrix_size) do
    options
    |> Enum.into(@defaults)
    |> calc_module_size(matrix_size)
  end

  defp calc_module_size(%{width: width} = options, matrix_size) when is_integer(width) do
    size = (width / matrix_size) |> Float.round() |> trunc()
    Map.put(options, :module_size, size)
  end

  defp calc_module_size(options, _matrix_size), do: options

  defp png_chunk(type, binary) do
    length = byte_size(binary)
    crc = :erlang.crc32(type <> binary)

    [<<length::32>>, type, binary, <<crc::32>>]
  end

  defp pixels(matrix, options) do
    matrix
    |> Tuple.to_list()
    |> Stream.map(&row_pixels(&1, options))
    |> Enum.join()
    |> :zlib.compress()
  end

  defp row_pixels(row, %{module_size: module_size} = options) do
    pixels =
      row
      |> Tuple.to_list()
      |> Enum.map(&module_pixels(&1, options))
      |> Enum.join()

    :binary.copy(<<0>> <> pixels, module_size)
  end

  defp module_pixels(value, %{background_color: background_color, module_size: module_size})
       when is_nil(value) or value == 0 do
    background_color
    |> apply_alpha_channel()
    |> :binary.copy(module_size)
  end

  defp module_pixels(1, %{color: color, module_size: module_size}) do
    color
    |> apply_alpha_channel()
    |> :binary.copy(module_size)
  end

  defp apply_alpha_channel(:transparent), do: <<0, 0, 0>> <> @transparent_alpha
  defp apply_alpha_channel(color), do: color <> @opaque_alpha
end
