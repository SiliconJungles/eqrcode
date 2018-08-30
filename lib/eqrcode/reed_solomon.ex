defmodule EQRCode.ReedSolomon do
  @moduledoc false

  import Bitwise

  @rs_block %{
    # version => {error_code_len, data_code_len, remainder_len}
    1 => {07, 019, 0},
    2 => {10, 034, 7},
    3 => {15, 055, 7},
    4 => {20, 080, 7},
    5 => {26, 108, 7},
    6 => {18, 068, 7},
    7 => {20, 078, 0}
  }
  @format_generator_polynomial 0b10100110111
  @format_mask 0b101010000010010

  @doc """
  Returns generator polynomials in alpha exponent for given error code length.

  Example:
      iex> EQRCode.ReedSolomon.generator_polynomial(10)
      [0, 251, 67, 46, 61, 118, 70, 64, 94, 32, 45]
  """
  def generator_polynomial(error_code_len)

  Stream.iterate({[0, 0], 1}, fn {e, i} ->
    {rest, last} =
      Stream.map(e, &rem(&1 + i, 255))
      |> Enum.split(i)

    rest =
      Stream.zip(rest, tl(e))
      |> Enum.map(fn {x, y} ->
        (EQRCode.GaloisField.to_i(x) ^^^ EQRCode.GaloisField.to_i(y))
        |> EQRCode.GaloisField.to_a()
      end)

    {[0] ++ rest ++ last, i + 1}
  end)
  |> Stream.take(32)
  |> Enum.each(fn {e, i} ->
    def generator_polynomial(unquote(i)), do: unquote(e)
  end)

  @doc """
  Reed-Solomon encode.

  Example:
      iex> EQRCode.ReedSolomon.encode(EQRCode.Encode.encode("hello world!"))
      <<64, 198, 134, 86, 198, 198, 242, 7, 118, 247, 38, 198, 66, 16,
        236, 17, 236, 17, 236, 45, 99, 25, 84, 35, 114, 46>>
  """
  @spec encode({integer, [0 | 1]}) :: [binary]
  def encode({version, message}) do
    {error_code_len, data_code_len, remainder_len} = @rs_block[version]
    gen_poly = generator_polynomial(error_code_len)

    data =
      Stream.chunk_every(message, 8)
      |> Stream.map(&String.to_integer(Enum.join(&1), 2))
      |> Stream.chunk_every(data_code_len)
      |> Stream.map(&{&1, polynomial_division(&1, gen_poly, data_code_len)})
      |> Enum.unzip()
      |> Tuple.to_list()
      |> Enum.flat_map(&interleave/1)
      |> :binary.list_to_bin()

    <<data::binary, 0::size(remainder_len)>>
  end

  defp interleave(list) do
    Enum.zip(list)
    |> Enum.flat_map(&Tuple.to_list/1)
  end

  @doc """
  Perform the polynomial division.

  Example:
      iex> EQRCode.ReedSolomon.polynomial_division([64, 198, 134, 86, 198, 198, 242, 7, 118, 247, 38, 198, 66, 16, 236, 17, 236, 17, 236], [0, 87, 229, 146, 149, 238, 102, 21], 19)
      [45, 99, 25, 84, 35, 114, 46]
  """
  @spec polynomial_division(list, list, integer) :: list
  def polynomial_division(msg_poly, gen_poly, data_code_len) do
    Stream.iterate(msg_poly, &do_polynomial_division(&1, gen_poly))
    |> Enum.at(data_code_len)
  end

  defp do_polynomial_division([0 | t], _), do: t

  defp do_polynomial_division([h | _] = msg, gen_poly) do
    Stream.map(gen_poly, &rem(&1 + EQRCode.GaloisField.to_a(h), 255))
    |> Enum.map(&EQRCode.GaloisField.to_i/1)
    |> pad_zip(msg)
    |> Enum.map(fn {a, b} -> a ^^^ b end)
    |> tl()
  end

  defp pad_zip(left, right) do
    [short, long] = Enum.sort_by([left, right], &length/1)

    Stream.concat(short, Stream.cycle([0]))
    |> Stream.zip(long)
  end

  def bch_encode(data) do
    bch = do_bch_encode(EQRCode.Encode.bits(<<data::bits, 0::10>>))

    (EQRCode.Encode.bits(data) ++ bch)
    |> Stream.zip(EQRCode.Encode.bits(<<@format_mask::15>>))
    |> Enum.map(fn {a, b} -> a ^^^ b end)
  end

  defp do_bch_encode(list) when length(list) == 10, do: list
  defp do_bch_encode([0 | t]), do: do_bch_encode(t)

  defp do_bch_encode(list) do
    EQRCode.Encode.bits(<<@format_generator_polynomial::11>>)
    |> Stream.concat(Stream.cycle([0]))
    |> Stream.zip(list)
    |> Enum.map(fn {a, b} -> a ^^^ b end)
    |> do_bch_encode()
  end
end
