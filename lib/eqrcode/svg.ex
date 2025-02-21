defmodule EQRCode.SVG do
  @moduledoc """
  Render the QR Code matrix in SVG format
  """

  alias EQRCode.Matrix

  @doc """
  Returns the SVG format of the QR Code.

  ## Options

  You can specify the following attributes of the QR code:

  * `:background_color` - In hexadecimal format or `:transparent`. The default is `#FFF`

  * `:color` - In hexadecimal format. The default is `#000`

  * `:shape` - Only `square` or `circle`. The default is `square`

  * `:width` - The width of the QR code in pixel. Without the width attribute,
    the QR code size will be dynamically generated based on the input string.

  * `:viewbox` - When set to `true`, the SVG element will specify its height and
    width using `viewBox`, instead of explicit `height` and `width` tags.

  * `:id` - An id to add to the svg

  * `:class` - HTML classes to apply to the svg

  Default options are `[color: "#000", shape: "square", background_color: "#FFF"]`.

  ## Examples

      qr_code_content
      |> EQRCode.encode()
      |> EQRCode.svg(color: "#cc6600", shape: "circle", width: 300)

  """
  @spec svg(Matrix.t(), map() | Keyword.t()) :: String.t()
  def svg(m, options \\ [])

  def svg(%Matrix{} = m, options) when is_map(options) do
    svg(m, Map.to_list(options))
  end

  def svg(%Matrix{matrix: matrix} = m, options) when is_list(options) do
    matrix_size = Matrix.size(m)
    svg_options = options |> Map.new() |> set_svg_options(matrix_size)
    dimension = matrix_size * svg_options[:module_size]
    xml_tag = ~s(<?xml version="1.0" standalone="yes"?>)

    attrs =
      [
        {:version, "1.1"},
        {:xmlns, "http://www.w3.org/2000/svg"},
        {:"xmlns:xlink", "http://www.w3.org/1999/xlink"},
        {:"xmlns:ev", "http://www.w3.org/2001/xml-events"},
        {:viewBox, "0 0 #{matrix_size} #{matrix_size}"},
        {:"shape-rendering", "crispEdges"},
        {:style, "background-color: #{svg_options[:background_color]}"}
        | Keyword.take(options, [:id, :class])
      ]
      |> then(fn attrs ->
        if Keyword.get(options, :viewbox, false) do
          attrs
        else
          [{:width, dimension}, {:height, dimension} | attrs]
        end
      end)
      |> Enum.map(fn {key, val} -> ~s(#{key}="#{val}") end)
      |> Enum.join(" ")

    open_tag =
      ~s(<svg #{attrs}>)

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
    |> Map.put_new(:background_color, "#FFF")
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

  defp substitute(data, row_num, col_num, %{background_color: background_color})
       when is_nil(data) or data == 0 do
    %{}
    |> Map.put(:height, 1)
    |> Map.put(:style, "fill: #{background_color};")
    |> Map.put(:width, 1)
    |> Map.put(:x, col_num)
    |> Map.put(:y, row_num)
    |> draw_rect
  end

  # This pattern match ensures that the QR Codes positional markers are drawn
  # as rectangles, regardless of the shape
  defp substitute(1, row_num, col_num, %{color: color, size: size})
       when (row_num <= 8 and col_num <= 8) or
              (row_num >= size - 9 and col_num <= 8) or
              (row_num <= 8 and col_num >= size - 9) do
    %{}
    |> Map.put(:height, 1)
    |> Map.put(:style, "fill: #{color};")
    |> Map.put(:width, 1)
    |> Map.put(:x, col_num)
    |> Map.put(:y, row_num)
    |> draw_rect
  end

  defp substitute(1, row_num, col_num, %{color: color, shape: "circle"}) do
    radius = 0.5

    %{}
    |> Map.put(:cx, col_num + radius)
    |> Map.put(:cy, row_num + radius)
    |> Map.put(:r, radius)
    |> Map.put(:style, "fill: #{color};")
    |> draw_circle
  end

  defp substitute(1, row_num, col_num, %{color: color}) do
    %{}
    |> Map.put(:height, 1)
    |> Map.put(:style, "fill: #{color};")
    |> Map.put(:width, 1)
    |> Map.put(:x, col_num)
    |> Map.put(:y, row_num)
    |> draw_rect
  end

  defp draw_rect(attribute_map) do
    attributes = get_attributes(attribute_map)
    ~s(<rect #{attributes}/>)
  end

  defp draw_circle(attribute_map) do
    attributes = get_attributes(attribute_map)
    ~s(<circle #{attributes}/>)
  end

  defp get_attributes(attribute_map) do
    attribute_map
    |> Enum.map(fn {key, value} -> ~s(#{key}="#{value}") end)
    |> Enum.join(" ")
  end
end
