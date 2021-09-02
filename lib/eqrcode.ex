defmodule EQRCode do
  @moduledoc """
  Simple QR Code Generator written in Elixir with no other dependencies.
  """

  alias EQRCode.{Encode, ReedSolomon, Matrix}

  @type error_correction_level :: :l | :m | :q | :h

  @doc """
  Encode the binary.
  """
  @spec encode(binary, error_correction_level()) :: Matrix.t()
  def encode(bin, error_correction_level \\ :l)

  def encode(bin, error_correction_level) when byte_size(bin) <= 2952 do
    {version, error_correction_level, data} =
      Encode.encode(bin, error_correction_level)
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

  def encode(bin, _error_correction_level) when is_nil(bin) do
    raise(ArgumentError, message: "you must pass in some input")
  end

  def encode(_, _),
    do: raise(ArgumentError, message: "your input is too long. keep it under 2952 characters")

  @doc """
  Encode the binary with custom pattern bits.

  Only supports version 5.
  """
  @spec encode(binary, error_correction_level(), bitstring) :: Matrix.t()
  def encode(bin, error_correction_level, bits) when byte_size(bin) <= 106 do
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

  def encode(_, _, _), do: IO.puts("Binary too long.")

  defdelegate svg(matrix, options \\ []), to: EQRCode.SVG

  defdelegate png(matrix, options \\ []), to: EQRCode.PNG

  defdelegate render(matrix), to: EQRCode.Render
end
