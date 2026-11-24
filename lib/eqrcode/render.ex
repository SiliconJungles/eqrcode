defmodule EQRCode.Render do
  @moduledoc """
  Render the QR Code matrix to the terminal.

  Taken essentially verbatim from https://github.com/sunboshan/qrcode
  """

  @doc """
  Render the QR Code to terminal.

  ## Options

  - `:compact` - Use compact rendering with Unicode block characters (default: `false`)
  - `:inverse` - Invert colors for dark terminal backgrounds (default: `false`)

  ## Examples

      qr_code_content
      |> EQRCode.encode()
      |> EQRCode.render()

      # Compact + inverted colors
      qr_code_content
      |> EQRCode.encode()
      |> EQRCode.render(compact: true, inverse: true)

  """
  @spec render(EQRCode.Matrix.t(), keyword()) :: :ok
  def render(matrix, opts \\ [])

  def render(%EQRCode.Matrix{matrix: matrix}, opts) when is_list(opts) do
    %{compact: compact, inverse: inverse} = validate_opts!(opts)

    rows = to_rows(matrix)

    if compact do
      render_compact(rows, inverse)
    else
      render_matrix(rows, inverse)
    end
  end

  defp render_compact(rows, inverse) do
    {bg, fg} = if inverse, do: {"\e[40m", "\e[37m"}, else: {"\e[47m", "\e[30m"}

    line_setup = bg <> fg
    reset = "\e[0m"

    rows
    |> Enum.chunk_every(2, 2, [Stream.repeatedly(fn -> 0 end)])
    |> Enum.map(fn [top_row, bottom_row] ->
      line = Enum.zip(top_row, bottom_row) |> Enum.map(fn {t, b} -> block_char(t, b) end)
      [line_setup, line, reset]
    end)
    |> Enum.intersperse("\n")
    |> IO.puts()
  end

  # Unicode half-block character mapping.
  # Top pixel is the upper half, bottom pixel is the lower half.
  # 1 = dark, anything else = light
  defp block_char(1, 1), do: "█"
  defp block_char(1, _), do: "▀"
  defp block_char(_, 1), do: "▄"
  defp block_char(_, _), do: " "

  @doc """
  Rotate the QR Code 90 degree clockwise and render to terminal. 
  """
  @spec render2(EQRCode.Matrix.t(), keyword()) :: :ok
  def render2(%EQRCode.Matrix{matrix: matrix}, opts \\ []) when is_list(opts) do
    %{compact: compact, inverse: inverse} = validate_opts!(opts)

    rows =
      matrix
      |> to_rows()
      |> Enum.reverse()
      |> transform()

    if compact do
      render_compact(rows, inverse)
    else
      render_matrix(rows, inverse)
    end
  end

  defp to_rows(matrix) do
    for row <- Tuple.to_list(matrix), do: Tuple.to_list(row)
  end

  defp validate_opts!(opts) do
    Keyword.validate!(opts, compact: false, inverse: false)
    |> Map.new()
  end

  defp render_matrix(rows, inverse) do
    rows
    |> Stream.map(fn row ->
      Enum.map(row, &do_render(&1, inverse))
    end)
    |> Enum.intersperse("\n")
    |> IO.puts()
  end

  defp do_render(1, false), do: "\e[40m  \e[0m"
  defp do_render(0, false), do: "\e[0;107m  \e[0m"
  defp do_render(1, true), do: do_render(0, false)
  defp do_render(0, true), do: do_render(1, false)
  defp do_render(nil, _inverse), do: "\e[0;106m  \e[0m"
  defp do_render(:data, _inverse), do: "\e[0;102m  \e[0m"
  defp do_render(:reserved, _inverse), do: "\e[0;104m  \e[0m"

  defp transform(matrix) do
    for e <- Enum.zip(matrix), do: Tuple.to_list(e)
  end
end
