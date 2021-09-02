defmodule EQRCode.Encode do
  @moduledoc """
  Data encoding in Byte Mode.
  """

  alias EQRCode.SpecTable
  import Bitwise

  @error_correction_level SpecTable.error_correction_level()

  @pad <<236, 17>>
  @mask0 <<0x99999999999999666666666666669966666666659999999996699533333333332CCD332CCCCCCCCCCCCCCD333333333333332CCD332CCCCCCCCCCCCCCD333333333333332CCD332CCCCCCCCCCCCCCD333333333333332CCD332CCCCCCCCCCCCCCD333333333333332CCD332CCCCCCCCCCCCCCD33333333333333333332CCCCCCCCCD33333333::1072>>

  @doc """
  Encode the binary.

  Example:
      iex> EQRCode.Encode.encode("hello world!", :l)
      {1, :l, [0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1,
       0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1,
       0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1,
       1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0,
       0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1,
       1, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0]}
  """
  @spec encode(binary, SpecTable.error_correction_level()) :: {SpecTable.version(), SpecTable.error_correction_level(), [0 | 1]}
  def encode(bin, error_correction_level) when error_correction_level in @error_correction_level do
    {:ok, version} = version(bin, error_correction_level)
    cci_len = SpecTable.character_count_indicator_bits(version, error_correction_level)
    mode = SpecTable.mode_indicator()

    encoded =
      [<<mode::4>>, <<byte_size(bin)::size(cci_len)>>, bin, <<0::4>>]
      |> Enum.flat_map(&bits/1)
      |> pad_bytes(version, error_correction_level)

    {version, error_correction_level, encoded}
  end

  # Encode the binary with custom pattern bits.
  @spec encode(binary, SpecTable.error_correction_level(), bitstring) :: {SpecTable.version(), SpecTable.error_correction_level(), [0 | 1]}
  def encode(bin, error_correction_level, bits) when error_correction_level in @error_correction_level do
    version = 5
    n = byte_size(bin)
    n1 = n + 2
    n2 = SpecTable.code_words_len(version, error_correction_level) - n1
    cci_len = SpecTable.character_count_indicator_bits(version, error_correction_level)
    mode = SpecTable.mode_indicator()
    <<_::binary-size(n1), mask::binary-size(n2), _::binary>> = @mask0

    encoded =
      <<mode::4, n::size(cci_len), bin::binary-size(n), 0::4, xor(bits, mask)::bits>>
      |> bits()
      |> pad_bytes(version, error_correction_level)

    {version, error_correction_level, encoded}
  end

  defp xor(<<>>, _), do: <<>>
  defp xor(_, <<>>), do: <<>>

  defp xor(<<a::1, t1::bits>>, <<b::1, t2::bits>>) do
    <<bxor(a, b)::1, xor(t1, t2)::bits>>
  end

  @doc """
  Returns the lowest version for the given binary.

  Example:
      iex> EQRCode.Encode.version("hello world!", :l)
      {:ok, 1}
  """
  @spec version(binary, SpecTable.error_correction_level()) :: {:error, :no_version_found} | {:ok, SpecTable.version()}
  def version(bin, error_correction_level) do
    byte_size(bin)
    |> SpecTable.find_version(error_correction_level)
  end

  @doc """
  Returns bits for any binary data.

  Example:
      iex> EQRCode.Encode.bits(<<123, 4>>)
      [0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0]
  """
  @spec bits(bitstring) :: [0 | 1]
  def bits(bin) do
    for <<b::1 <- bin>>, do: b
  end

  defp pad_bytes(list, version, error_correction_level) do
    n = SpecTable.code_words_len(version, error_correction_level) * 8 - length(list)

    Enum.concat(
      list,
      Stream.cycle(bits(@pad))
      |> Stream.take(n)
    )
  end
end
