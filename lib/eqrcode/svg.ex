defmodule EQRCode.Svg do
  @moduledoc """
  Render the QR Code matrix in SVG format
  """

  @doc """
  Return the SVG format of the QR Code
  """
  def svg(%EQRCode.Matrix{matrix: matrix}, options) do
    matrix_size = matrix |> Tuple.to_list() |> Enum.count()
    svg_options = options |> set_svg_options(matrix_size)
    dimension = matrix_size * svg_options[:module_size]

    xml_tag = ~s(<?xml version="1.0" standalone="yes"?>)

    open_tag =
      ~s(<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events" width="#{
        dimension
      }" height="#{dimension}" shape-rendering="crispEdges">)

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
    |> Map.put_new(:module_size, 11)
    |> Map.put_new(:shape, "rectangle")
    |> Map.put_new(:size, matrix_size)
  end

  defp format_row_as_svg(row_matrix, row_num, svg_options) do
    row_matrix
    |> Stream.with_index()
    |> Stream.map(fn {col, col_num} ->
      substitute(col, row_num, col_num, svg_options)
    end)
    |> Enum.to_list()
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
