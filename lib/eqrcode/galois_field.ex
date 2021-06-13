defmodule EQRCode.GaloisField do
  @moduledoc false

  import Bitwise

  @doc """
  Given alpha exponent returns integer.

  ## Examples

      iex> EQRCode.GaloisField.to_i(1)
      2

  """
  @spec to_i(integer) :: integer
  def to_i(alpha)

  @doc """
  Given integer returns alpha exponent.

  ## Examples

      iex> EQRCode.GaloisField.to_a(2)
      1

  """
  @spec to_a(integer) :: integer
  def to_a(integer)

  Stream.iterate({1, 0}, fn {e, i} ->
    n = e <<< 1
    {if(n >= 256, do: n ^^^ 0b100011101, else: n), i + 1}
  end)
  |> Enum.take(256)
  |> Enum.map(fn {e, i} ->
    def to_i(unquote(i)), do: unquote(e)
    def to_a(unquote(e)), do: unquote(i)
  end)
end
