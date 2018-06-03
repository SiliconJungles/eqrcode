defmodule EQRCode.Encode do
  @moduledoc """
  Data encoding in Byte Mode.
  """

  import Bitwise

  @byte_mode 0b0100
  @pad <<236, 17>>
  @capacity_l [0, 17, 32, 53, 78, 106, 134, 154]
  @ecc_l %{
    1 => 19,
    2 => 34,
    3 => 55,
    4 => 80,
    5 => 108,
    6 => 136,
    7 => 156
  }
  @mask0 <<0x99999999999999666666666666669966666666659999999996699533333333332CCD332CCCCCCCCCCCCCCD333333333333332CCD332CCCCCCCCCCCCCCD333333333333332CCD332CCCCCCCCCCCCCCD333333333333332CCD332CCCCCCCCCCCCCCD333333333333332CCD332CCCCCCCCCCCCCCD33333333333333333332CCCCCCCCCD33333333::1072>>

  @doc """
  Encode the binary.

  Example:
      iex> QRCode.Encode.encode("hello world!")
      {1, [0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1,
       0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1,
       0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1,
       1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0,
       0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1,
       1, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0]}
  """
  @spec encode(binary) :: {integer, [0 | 1]}
  def encode(bin) do
    version = version(bin)

    encoded =
      [<<@byte_mode::4>>, <<byte_size(bin)>>, bin, <<0::4>>]
      |> Enum.flat_map(&bits/1)
      |> pad_bytes(version)

    {version, encoded}
  end

  @doc """
  Encode the binary with custom pattern bits.
  """
  @spec encode(binary, bitstring) :: {integer, [0 | 1]}
  def encode(bin, bits) do
    version = 5
    n = byte_size(bin)
    n1 = n + 2
    n2 = @ecc_l[version] - n1
    <<_::binary-size(n1), mask::binary-size(n2), _::binary>> = @mask0

    encoded =
      <<@byte_mode::4, n::8, bin::binary-size(n), 0::4, xor(bits, mask)::bits>>
      |> bits()
      |> pad_bytes(version)

    {version, encoded}
  end

  defp xor(<<>>, _), do: <<>>
  defp xor(_, <<>>), do: <<>>

  defp xor(<<a::1, t1::bits>>, <<b::1, t2::bits>>) do
    <<a ^^^ b::1, xor(t1, t2)::bits>>
  end

  @doc """
  Returns the lowest version for the given binary.

  Example:
      iex> QRCode.Encode.version("hello world!")
      1
  """
  @spec version(binary) :: integer
  def version(bin) do
    len = byte_size(bin)
    Enum.find_index(@capacity_l, &(&1 >= len))
  end

  @doc """
  Returns bits for any binary data.

  Example:
      iex> QRCode.Encode.bits(<<123, 4>>)
      [0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0]
  """
  @spec bits(bitstring) :: [0 | 1]
  def bits(bin) do
    for <<b::1 <- bin>>, do: b
  end

  defp pad_bytes(list, version) do
    n = @ecc_l[version] * 8 - length(list)

    Stream.cycle(bits(@pad))
    |> Stream.take(n)
    |> (&Enum.concat(list, &1)).()
  end
end
