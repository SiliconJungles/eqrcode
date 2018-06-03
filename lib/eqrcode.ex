defmodule EQRCode do
  @moduledoc """
  QR Code implementation in Elixir.

  Spec:
    - Version: 1 - 7
    - ECC level: L
    - Encoding mode: Byte

  References:
    - ISO/IEC 18004:2006(E)
    - http://www.thonky.com/qr-code-tutorial/
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

  defdelegate svg(matrix, options \\ %{}), to: EQRCode.Svg
end
