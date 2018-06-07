defmodule EQRCode.Mask do
  @moduledoc false

  @doc """
  Get the total score for the masked matrix.
  """
  @spec score(EQRCode.Matrix.matrix()) :: integer
  def score(matrix) do
    rule1(matrix) + rule2(matrix) + rule3(matrix) + rule4(matrix)
  end

  @doc """
  Check for consecutive blocks.
  """
  @spec rule1(EQRCode.Matrix.matrix()) :: integer
  def rule1(matrix) do
    matrix = for e <- Tuple.to_list(matrix), do: Tuple.to_list(e)

    Stream.concat(matrix, transform(matrix))
    |> Enum.reduce(0, &(do_rule1(&1, {nil, 0}, 0) + &2))
  end

  defp do_rule1([], _, acc), do: acc
  defp do_rule1([h | t], {_, 0}, acc), do: do_rule1(t, {h, 1}, acc)
  defp do_rule1([h | t], {h, 4}, acc), do: do_rule1(t, {h, 5}, acc + 3)
  defp do_rule1([h | t], {h, 5}, acc), do: do_rule1(t, {h, 5}, acc + 1)
  defp do_rule1([h | t], {h, n}, acc), do: do_rule1(t, {h, n + 1}, acc)
  defp do_rule1([h | t], {_, _}, acc), do: do_rule1(t, {h, 1}, acc)

  defp transform(matrix) do
    for e <- Enum.zip(matrix), do: Tuple.to_list(e)
  end

  @doc """
  Check for 2x2 blocks.
  """
  @spec rule2(EQRCode.Matrix.matrix()) :: integer
  def rule2(matrix) do
    z = tuple_size(matrix) - 2

    for i <- 0..z,
        j <- 0..z do
      EQRCode.Matrix.shape({i, j}, {2, 2})
      |> Enum.map(&get(matrix, &1))
    end
    |> Enum.reduce(0, &do_rule2/2)
  end

  defp do_rule2([1, 1, 1, 1], acc), do: acc + 3
  defp do_rule2([0, 0, 0, 0], acc), do: acc + 3
  defp do_rule2([_, _, _, _], acc), do: acc

  @doc """
  Check for special blocks.
  """
  @spec rule3(EQRCode.Matrix.matrix()) :: integer
  def rule3(matrix) do
    z = tuple_size(matrix)

    for i <- 0..(z - 1),
        j <- 0..(z - 11) do
      [{{i, j}, {11, 1}}, {{j, i}, {1, 11}}]
      |> Stream.map(fn {a, b} ->
        EQRCode.Matrix.shape(a, b)
        |> Enum.map(&get(matrix, &1))
      end)
      |> Enum.map(&do_rule3/1)
    end
    |> List.flatten()
    |> Enum.sum()
  end

  defp do_rule3([1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0]), do: 40
  defp do_rule3([0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1]), do: 40
  defp do_rule3([_, _, _, _, _, _, _, _, _, _, _]), do: 0

  @doc """
  Check for module's proportion.
  """
  @spec rule4(EQRCode.Matrix.matrix()) :: integer
  def rule4(matrix) do
    m = tuple_size(matrix)

    black =
      Tuple.to_list(matrix)
      |> Enum.reduce(0, fn e, acc ->
        Tuple.to_list(e)
        |> Enum.reduce(acc, &do_rule4/2)
      end)

    div(abs(div(black * 100, m * m) - 50), 5) * 10
  end

  defp do_rule4(1, acc), do: acc + 1
  defp do_rule4(_, acc), do: acc

  defp get(matrix, {x, y}) do
    get_in(matrix, [Access.elem(x), Access.elem(y)])
  end

  @doc """
  The mask algorithm.
  """
  @spec mask(integer, EQRCode.Matrix.coordinate()) :: 0 | 1
  def mask(0b000, {x, y}) when rem(x + y, 2) == 0, do: 1
  def mask(0b000, {_, _}), do: 0
  def mask(0b001, {x, _}) when rem(x, 2) == 0, do: 1
  def mask(0b001, {_, _}), do: 0
  def mask(0b010, {_, y}) when rem(y, 3) == 0, do: 1
  def mask(0b010, {_, _}), do: 0
  def mask(0b011, {x, y}) when rem(x + y, 3) == 0, do: 1
  def mask(0b011, {_, _}), do: 0
  def mask(0b100, {x, y}) when rem(div(x, 2) + div(y, 3), 2) == 0, do: 1
  def mask(0b100, {_, _}), do: 0
  def mask(0b101, {x, y}) when rem(x * y, 2) + rem(x * y, 3) == 0, do: 1
  def mask(0b101, {_, _}), do: 0
  def mask(0b110, {x, y}) when rem(rem(x * y, 2) + rem(x * y, 3), 2) == 0, do: 1
  def mask(0b110, {_, _}), do: 0
  def mask(0b111, {x, y}) when rem(rem(x + y, 2) + rem(x * y, 3), 2) == 0, do: 1
  def mask(0b111, {_, _}), do: 0
end
