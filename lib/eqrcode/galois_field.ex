defmodule EQRCode.GaloisField do
  @moduledoc false

  import Bitwise

  @integers %{}
  @alphas %{}

  Stream.iterate(1, fn e ->
    n = e <<< 1
    if n >= 256, do: n ^^^ 0b100011101, else: n
  end)
  |> Stream.take(256)
  |> Stream.with_index()
  |> Enum.each(fn {e, i} ->
    Module.put_attribute(__MODULE__, :alphas, Map.put(@alphas, e, i))
    Module.put_attribute(__MODULE__, :integers, Map.put(@integers, i, e))
  end)

  @doc """
  Given alpha exponent returns integer.

  Example:
      iex> EQRCode.GaloisField.to_i(1)
      2
  """
  @spec to_i(integer) :: integer
  def to_i(alpha) do
    @integers[alpha]
  end

  @doc """
  Given integer returns alpha exponent.

  Example:
      iex> EQRCode.GaloisField.to_a(2)
      1
  """
  @spec to_a(integer) :: integer
  def to_a(integer) do
    @alphas[integer]
  end
end
