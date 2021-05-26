defmodule EQRCode.ReedSolomon do
  @moduledoc false

  import Bitwise
  alias EQRCode.SpecTable

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
        (bxor(EQRCode.GaloisField.to_i(x), EQRCode.GaloisField.to_i(y)))
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
      iex> EQRCode.ReedSolomon.encode(EQRCode.Encode.encode("hello world!", :l))
      {1, :l, <<64, 198, 134, 86, 198, 198, 242, 7, 118, 247, 38, 198, 66, 16,
        236, 17, 236, 17, 236, 45, 99, 25, 84, 35, 114, 46>>}
  """
  @spec encode({SpecTable.version(), SpecTable.error_correction_level(), [0 | 1]}) :: {SpecTable.version(), SpecTable.error_correction_level(), bitstring()}
  def encode({version, error_correction_level, message}) do
    remainder_len = SpecTable.remainer(version)

    data =
      Enum.chunk_every(message, 8)
      |> Enum.map(&String.to_integer(Enum.join(&1), 2))
      |> chunk_and_devide_groups(version, error_correction_level)
      |> Enum.unzip()
      |> interleave()
      |> :binary.list_to_bin()

    {version, error_correction_level, <<data::binary, 0::size(remainder_len)>>}
  end

  def count(d) when is_map(d), do: count(d |> Map.values())
  def count(d) when is_tuple(d), do: count(d |> Tuple.to_list())
  def count(d) when is_list(d), do: Enum.reduce(d, 0, fn e, acc -> acc + count(e) end)
  def count(_), do: 1

  def print_count(d) do
    count(d) |> IO.inspect(label: "#{__ENV__.file}:#{__ENV__.line}")
    d
  end

  def chunk_and_devide_groups(enum, version, error_correction_level) do
    group1_data_code_len = SpecTable.group1_codewords_per_block(version, error_correction_level)
    group1_block_len = SpecTable.group1_block_len(version, error_correction_level)

    group2_data_code_len = SpecTable.group2_codewords_per_block(version, error_correction_level)
    group2_block_len = SpecTable.group2_block_len(version, error_correction_level)

    error_code_len = SpecTable.ec_codewords_per_block(version, error_correction_level)
    gen_poly = generator_polynomial(error_code_len)

    {group1, enum} = group(enum, group1_block_len, group1_data_code_len)
    {group2, _enum} = group(enum, group2_block_len, group2_data_code_len)

    Enum.concat(
      group1
      |> Enum.map(&group_devisions(&1, gen_poly, group1_data_code_len)),
      group2
      |> Enum.map(&group_devisions(&1, gen_poly, group2_data_code_len))
    )
  end

  defp group(enum, 0, _data_code_len) do
    {[], enum}
  end

  defp group(enum, block_len, data_code_len) do
    {
      Enum.take(enum, block_len * data_code_len)
      |> Enum.chunk_every(data_code_len),
      Enum.drop(enum, block_len * data_code_len)
    }
  end

  defp group_devisions(group, gen_poly, data_code_len) do
    {group, polynomial_division(group, gen_poly, data_code_len)}
  end

  def interleave(data, acc \\ [])
  def interleave({[], error_code_sec}, acc), do: interleave_sec(error_code_sec, acc) |> Enum.reverse()
  def interleave({code_sec, ec}, acc), do: interleave({[], ec}, interleave_sec(code_sec, acc))

  @doc """
  ## Example
  iex> EQRCode.ReedSolomon.interleave_sec([[1, 2], [6, 7], [3, 4, 5], [8, 9, 10]], []) |> Enum.reverse()
  [1, 6, 3, 8, 2, 7, 4, 9, 5, 10]

  iex> EQRCode.ReedSolomon.interleave_sec([[]], [])
  []
  """
  def interleave_sec([], acc), do: acc

  def interleave_sec(data, acc) do
    for [h | tail] <- data do {h, tail} end
    |> Enum.unzip()
    |> case do
      {l, rest} -> interleave_sec(rest, Enum.concat(Enum.reverse(l), acc))
    end
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
  defp do_polynomial_division([], _), do: []

  defp do_polynomial_division([h | _] = msg, gen_poly) do
    Enum.map(gen_poly, &rem(&1 + EQRCode.GaloisField.to_a(h), 255))
    |> Enum.map(&EQRCode.GaloisField.to_i/1)
    |> pad_zip(msg)
    |> Enum.map(fn {a, b} -> bxor(a, b) end)
    |> tl()
  end

  # def my_len(v) when is_tuple(v), do: v |> Tuple.to_list() |> Enum.map(&my_len/1)
  # def my_len(v = [p|_]) when is_list(p), do: v |> Enum.map(&my_len/1)
  # def my_len(v = [p|_]) when is_tuple(p), do: v |> Enum.map(&my_len/1)
  # def my_len(v), do: length(v)

  # def len_inspect(v) do
  #   my_len(v) |> IO.inspect(label: "#{__ENV__.file}:#{__ENV__.line}")
  #   v
  #   |> IO.inspect(label: "#{__ENV__.file}:#{__ENV__.line}")
  # end

  defp pad_zip(left, right) do
    [short, long] = Enum.sort_by([left, right], &length/1)

    Stream.concat(short, Stream.cycle([0]))
    |> Stream.zip(long)
  end

  def bch_encode(data) do
    bch = do_bch_encode(EQRCode.Encode.bits(<<data::bits, 0::10>>))

    (EQRCode.Encode.bits(data) ++ bch)
    |> Stream.zip(EQRCode.Encode.bits(<<@format_mask::15>>))
    |> Enum.map(fn {a, b} -> bxor(a, b) end)
  end

  defp do_bch_encode(list) when length(list) == 10, do: list
  defp do_bch_encode([0 | t]), do: do_bch_encode(t)

  defp do_bch_encode(list) do
    EQRCode.Encode.bits(<<@format_generator_polynomial::11>>)
    |> Stream.concat(Stream.cycle([0]))
    |> Stream.zip(list)
    |> Enum.map(fn {a, b} -> bxor(a, b) end)
    |> do_bch_encode()
  end
end
