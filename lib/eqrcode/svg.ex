defmodule EQRCode.SVG do
  @moduledoc """
  Render the QR Code matrix in SVG format

  ```elixir
  qr_code_content
  |> EQRCode.encode()
  |> EQRCode.svg(color: "#cc6600", shape: "circle", width: 300)
  ```

  You can specify the following attributes of the QR code:

  * `color`: In hexadecimal format. The default is `#000`
  * `shape`: Only `square` or `circle`. The default is `square`
  * `width`: The width of the QR code in pixel. Without the width attribute, the QR code size will be dynamically generated based on the input string.
  * `viewbox`: When set to `true`, the SVG element will specify its height and width using `viewBox`, instead of explicit `height` and `width` tags.

  Default options are `[color: "#000", shape: "square"]`.

  """

  alias EQRCode.Matrix

  @doc """
  Return the SVG format of the QR Code
  """
  @spec svg(Matrix.t(), map() | Keyword.t()) :: String.t()
  def svg(%Matrix{matrix: matrix} = m, options \\ []) do
    options = options |> Enum.map(& &1)
    matrix_size = Matrix.size(m)
    svg_options = options |> Map.new() |> set_svg_options(matrix_size)
    dimension = matrix_size * svg_options[:module_size]

    xml_tag = ~s(<?xml version="1.0" standalone="yes"?>)

    dimension_attrs =
      if Keyword.get(options, :viewbox, false) do
        ~s(viewBox="0 0 #{dimension} #{dimension}")
      else
        ~s(width="#{dimension}" height="#{dimension}")
      end

    open_tag =
      ~s(<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events" #{
        dimension_attrs
      }
      shape-rendering="crispEdges">)

    close_tag = ~s(</svg>)

    result =
      Tuple.to_list(matrix)
      |> Stream.with_index()
      |> Stream.map(fn {row, row_num} ->
        Tuple.to_list(row)
        |> format_row_as_svg(row_num, svg_options)
      end)
      |> Enum.to_list()

    Enum.join([xml_tag, open_tag, result, close_tag], "\n")
  end

  defp set_svg_options(options, matrix_size) do
    options
    |> Map.put_new(:color, "#000")
    |> set_module_size(matrix_size)
    |> Map.put_new(:shape, "rectangle")
    |> Map.put_new(:size, matrix_size)
  end

  defp set_module_size(%{width: width} = options, matrix_size) when is_integer(width) do
    options
    |> Map.put_new(:module_size, width / matrix_size)
  end

  defp set_module_size(%{width: width} = options, matrix_size) when is_binary(width) do
    options
    |> Map.put_new(:module_size, String.to_integer(width) / matrix_size)
  end

  defp set_module_size(options, _matrix_size) do
    options
    |> Map.put_new(:module_size, 11)
  end

  defp format_row_as_svg(row_matrix, row_num, svg_options) do
    row_matrix
    |> Stream.with_index()
    |> Stream.map(fn {col, col_num} ->
      substitute(col, row_num, col_num, svg_options)
    end)
    |> Enum.to_list()
  end

  defp substitute(data, row_num, col_num, svg_options) when is_nil(data) do
    y = col_num * svg_options[:module_size]
    x = row_num * svg_options[:module_size]

    ~s(<rect width="#{svg_options[:module_size]}" height="#{svg_options[:module_size]}" x="#{x}" y="#{
      y
    }" style="fill:#fff"/>)
  end

  defp substitute(1, row_num, col_num, %{shape: "circle", size: size} = svg_options) do
    y = col_num * svg_options[:module_size]
    x = row_num * svg_options[:module_size]

    if (row_num <= 8 && col_num <= 8) || (row_num >= size - 9 && col_num <= 8) ||
         (row_num <= 8 && col_num >= size - 9) do
      ~s(<rect width="#{svg_options[:module_size]}" height="#{svg_options[:module_size]}" x="#{x}" y="#{
        y
      }" style="fill:#{svg_options[:color]}"/>)
    else
      ~s(<circle r="#{svg_options[:module_size] / 2.0}" cx="#{x + svg_options[:module_size] / 2.0}" cy="#{
        y + svg_options[:module_size] / 2.0
      }" style="fill:#{svg_options[:color]};"/>)
    end
  end

  defp substitute(1, row_num, col_num, svg_options) do
    y = col_num * svg_options[:module_size]
    x = row_num * svg_options[:module_size]

    ~s(<rect width="#{svg_options[:module_size]}" height="#{svg_options[:module_size]}" x="#{x}" y="#{
      y
    }" style="fill:#{svg_options[:color]}"/>)
  end

  defp substitute(0, row_num, col_num, svg_options) do
    y = col_num * svg_options[:module_size]
    x = row_num * svg_options[:module_size]

    ~s(<rect width="#{svg_options[:module_size]}" height="#{svg_options[:module_size]}" x="#{x}" y="#{
      y
    }" style="fill:#fff"/>)
  end
end
