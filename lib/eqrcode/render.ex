defmodule EQRCode.Render do
  @moduledoc """
  Render the QR Code matrix.

  Taken essentially verbatim from https://github.com/sunboshan/qrcode
  """

  @doc """
  Render the QR Code to terminal.

  ## Examples

      qr_code_content
      |> EQRCode.encode()
      |> EQRCode.render()

  """
  @spec render(EQRCode.Matrix.t()) :: :ok
  def render(%EQRCode.Matrix{matrix: matrix}) do
    Tuple.to_list(matrix)
    |> Stream.map(fn e ->
      Tuple.to_list(e)
      |> Enum.map(&do_render/1)
    end)
    |> Enum.intersperse("\n")
    |> IO.puts()
  end

  defp do_render(1), do: "\e[40m  \e[0m"
  defp do_render(0), do: "\e[0;107m  \e[0m"
  defp do_render(nil), do: "\e[0;106m  \e[0m"
  defp do_render(:data), do: "\e[0;102m  \e[0m"
  defp do_render(:reserved), do: "\e[0;104m  \e[0m"

  @doc """
  Rotate the QR Code 90 degree clockwise and render to terminal.
  """
  @spec render2(EQRCode.Matrix.t()) :: :ok
  def render2(%EQRCode.Matrix{matrix: matrix}) do
    for(e <- Tuple.to_list(matrix), do: Tuple.to_list(e))
    |> Enum.reverse()
    |> transform()
    |> Stream.map(fn e ->
      Enum.map(e, &do_render/1)
    end)
    |> Enum.intersperse("\n")
    |> IO.puts()
  end

  defp transform(matrix) do
    for e <- Enum.zip(matrix), do: Tuple.to_list(e)
  end
end
