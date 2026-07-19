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

    image_tag =
      if inner_image = svg_options[:inner_image] do
        p = svg_options[:inner_image_size]
        padding = svg_options[:inner_image_padding]

        {w, h, x, y, bg_w, bg_h, bg_x, bg_y} =
          if svg_options[:align_to_grid] do
            # Round the image width and height to be divisible by the block size (1 module)
            # We round to the nearest odd integer so that centering aligns exactly on block boundaries.
            w_rounded = round_to_odd(matrix_size * p)
            x_rounded = (matrix_size - w_rounded) / 2

            # Round the quiet zone padding per side to the nearest integer number of blocks
            padding_blocks = if padding > 0.0, do: ceil(matrix_size * padding), else: 0

            # Background size is w_rounded + 2 * padding_blocks, which guarantees it remains odd and aligns perfectly to the grid.
            bg_w_rounded = w_rounded + padding_blocks * 2
            bg_x_rounded = (matrix_size - bg_w_rounded) / 2

            {w_rounded, w_rounded, x_rounded, x_rounded, bg_w_rounded, bg_w_rounded, bg_x_rounded, bg_x_rounded}
          else
            w_raw = matrix_size * p
            x_raw = (matrix_size - w_raw) / 2

            bg_w_raw = w_raw + (matrix_size * padding * 2)
            bg_x_raw = (matrix_size - bg_w_raw) / 2

            {w_raw, w_raw, x_raw, x_raw, bg_w_raw, bg_w_raw, bg_x_raw, bg_x_raw}
          end

        bg_rect =
          if svg_options[:background_color] not in [:transparent, "transparent"] do
            ~s(<rect x="#{bg_x}" y="#{bg_y}" width="#{bg_w}" height="#{bg_h}" fill="#{svg_options[:background_color]}"/>\n)
          else
            ""
          end

        image_element = ~s(<image href="#{inner_image}" x="#{x}" y="#{y}" width="#{w}" height="#{h}"/>)
        bg_rect <> image_element
      else
        ""
      end

    elements =
      if image_tag != "" do
        [xml_tag, open_tag, result, image_tag, close_tag]
      else
        [xml_tag, open_tag, result, close_tag]
      end

    Enum.join(elements, "\n")
  end

  defp set_svg_options(options, matrix_size) do
    options
    |> Map.put_new(:background_color, "#FFF")
    |> Map.put_new(:color, "#000")
    |> set_module_size(matrix_size)
    |> Map.put_new(:shape, "rectangle")
    |> Map.put_new(:size, matrix_size)
    |> set_image_options()
  end

  defp set_image_options(options) do
    inner_image = options[:inner_image]
    inner_image_size = options[:inner_image_size] || 0.15
    inner_image_padding = options[:inner_image_padding]  || 0.0
    align_to_grid = Map.get(options, :align_to_grid, true)

    options
    |> Map.put(:inner_image, inner_image)
    |> Map.put(:inner_image_size, normalize_image_size(inner_image_size))
    |> Map.put(:inner_image_padding, normalize_image_size(inner_image_padding))
    |> Map.put(:align_to_grid, align_to_grid)
  end

  defp normalize_image_size(size) when is_float(size) do
    if size >= 1.0 do
      size / 100
    else
      size
    end
  end

  defp normalize_image_size(_), do: 0.15

  defp round_to_odd(value) do
    r = round(value)
    r = if rem(r, 2) == 0 do
      if value > r, do: r + 1, else: r - 1
    else
      r
    end
    max(r, 1)
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
