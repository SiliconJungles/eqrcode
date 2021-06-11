defmodule EQRCode.GaloisField do
  @moduledoc false

  import Bitwise

  @gf256 (
    Stream.iterate({1, 0}, fn {e, i} ->
      n = e <<< 1
      {if(n >= 256, do: bxor(n, 0b100011101), else: n), i + 1}
    end)
    |> Enum.take(256)
    |> Enum.reduce({%{}, %{}}, fn {e, i}, {to_i, to_a} ->
      {Map.put(to_i, i, e), Map.put_new(to_a, e, i)}
    end)
  )

  @gf256_to_i elem(@gf256, 0)
  @gf256_to_a elem(@gf256, 1)

  @doc """
  Given alpha exponent returns integer.

  Example:
      iex> EQRCode.GaloisField.to_i(1)
      2
  """
  @spec to_i(integer) :: integer
  def to_i(alpha), do: @gf256_to_i[alpha]

  @doc """
  Given integer returns alpha exponent.

  Example:
      iex> EQRCode.GaloisField.to_a(2)
      1
  """
  @spec to_a(integer) :: integer
  def to_a(integer), do: @gf256_to_a[integer]
end
