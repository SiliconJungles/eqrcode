defmodule EQRCode.GaloisField do
  @moduledoc false

  import Bitwise

  @doc """
  Given alpha exponent returns integer.

  Example:
      iex> QRCode.GaloisField.to_i(1)
      2
  """
  @spec to_i(integer) :: integer
  def to_i(alpha)

  @doc """
  Given integer returns alpha exponent.

  Example:
      iex> QRCode.GaloisField.to_a(2)
      1
  """
  @spec to_a(integer) :: integer
  def to_a(integer)

  Stream.iterate(1, fn e ->
    n = e <<< 1
    if n >= 256, do: n ^^^ 0b100011101, else: n
  end)
  |> Stream.take(256)
  |> Stream.with_index()
  |> Enum.each(fn {e, i} ->
    def to_i(unquote(i)), do: unquote(e)
    def to_a(unquote(e)), do: unquote(i)
  end)
end
