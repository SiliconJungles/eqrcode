defmodule EQRCode.Matrix do
  @moduledoc false

  alias EQRCode.SpecTable

  import Bitwise

  @derive {Inspect, only: [:version, :error_correction_level, :modules, :mask]}
  defstruct [:version, :error_correction_level, :modules, :mask, :matrix]

  @type coordinate :: {non_neg_integer(), non_neg_integer()}
  @type matrix :: term
  @type t :: %__MODULE__{
          version: SpecTable.version(),
          error_correction_level: SpecTable.error_correction_level(),
          modules: integer,
          matrix: matrix
        }

  @alignments %{
    1 => [],
    2 => [6, 18],
    3 => [6, 22],
    4 => [6, 26],
    5 => [6, 30],
    6 => [6, 34],
    7 => [6, 22, 38],
    8 => [6, 24, 42],
    9 => [6, 26, 46],
    10 => [6, 28, 50],
    11 => [6, 30, 54],
    12 => [6, 32, 58],
    13 => [6, 34, 62],
    14 => [6, 26, 46, 66],
    15 => [6, 26, 48, 70],
    16 => [6, 26, 50, 74],
    17 => [6, 30, 54, 78],
    18 => [6, 30, 56, 82],
    19 => [6, 30, 58, 86],
    20 => [6, 34, 62, 90],
    21 => [6, 28, 50, 72, 94],
    22 => [6, 26, 50, 74, 98],
    23 => [6, 30, 54, 78, 102],
    24 => [6, 28, 54, 80, 106],
    25 => [6, 32, 58, 84, 110],
    26 => [6, 30, 58, 86, 114],
    27 => [6, 34, 62, 90, 118],
    28 => [6, 26, 50, 74, 98, 122],
    29 => [6, 30, 54, 78, 102, 126],
    30 => [6, 26, 52, 78, 104, 130],
    31 => [6, 30, 56, 82, 108, 134],
    32 => [6, 34, 60, 86, 112, 138],
    33 => [6, 30, 58, 86, 114, 142],
    34 => [6, 34, 62, 90, 118, 146],
    35 => [6, 30, 54, 78, 102, 126, 150],
    36 => [6, 24, 50, 76, 102, 128, 154],
    37 => [6, 28, 54, 80, 106, 132, 158],
    38 => [6, 32, 58, 84, 110, 136, 162],
    39 => [6, 26, 54, 82, 110, 138, 166],
    40 => [6, 30, 58, 86, 114, 142, 170]
  }

  @finder_pattern Code.eval_string("""
                  [
                    1, 1, 1, 1, 1, 1, 1,
                    1, 0, 0, 0, 0, 0, 1,
                    1, 0, 1, 1, 1, 0, 1,
                    1, 0, 1, 1, 1, 0, 1,
                    1, 0, 1, 1, 1, 0, 1,
                    1, 0, 0, 0, 0, 0, 1,
                    1, 1, 1, 1, 1, 1, 1
                  ]
                  """)
                  |> elem(0)

  @alignment_pattern Code.eval_string("""
                     [
                       1, 1, 1, 1, 1,
                       1, 0, 0, 0, 1,
                       1, 0, 1, 0, 1,
                       1, 0, 0, 0, 1,
                       1, 1, 1, 1, 1,
                     ]
                     """)
                     |> elem(0)

  @doc """
  Initialize the matrix.
  """
  @spec new(SpecTable.version(), SpecTable.error_correction_level()) :: t
  def new(version, error_correction_level \\ :l) do
    modules = (version - 1) * 4 + 21

    matrix =
      Tuple.duplicate(nil, modules)
      |> Tuple.duplicate(modules)

    %__MODULE__{
      version: version,
      error_correction_level: error_correction_level,
      modules: modules,
      matrix: matrix
    }
  end

  @doc """
  Draw the finder patterns, three at a time.
  """
  @spec draw_finder_patterns(t) :: t
  def draw_finder_patterns(%__MODULE__{matrix: matrix, modules: modules} = m) do
    z = modules - 7

    matrix =
      [{0, 0}, {z, 0}, {0, z}]
      |> Stream.flat_map(&shape(&1, {7, 7}))
      |> Stream.zip(Stream.cycle(@finder_pattern))
      |> Enum.reduce(matrix, fn {coordinate, v}, acc ->
        update(acc, coordinate, v)
      end)

    %{m | matrix: matrix}
  end

  @doc """
  Draw the seperators.
  """
  @spec draw_seperators(t) :: t
  def draw_seperators(%__MODULE__{matrix: matrix, modules: modules} = m) do
    z = modules - 8

    matrix =
      [
        {{0, 7}, {1, 8}},
        {{0, z}, {1, 8}},
        {{7, z}, {8, 1}},
        {{7, 0}, {8, 1}},
        {{z, 0}, {8, 1}},
        {{z, 7}, {1, 8}}
      ]
      |> Stream.flat_map(fn {a, b} -> shape(a, b) end)
      |> Enum.reduce(matrix, &update(&2, &1, 0))

    %{m | matrix: matrix}
  end

  @doc """
  Draw the alignment patterns.
  """
  @spec draw_alignment_patterns(t) :: t
  def draw_alignment_patterns(%__MODULE__{matrix: matrix, version: version} = m) do
    matrix =
      for(
        x <- @alignments[version],
        y <- @alignments[version],
        do: {x, y}
      )
      |> Stream.filter(&available?(matrix, &1))
      |> Stream.map(fn {x, y} -> {x - 2, y - 2} end)
      |> Stream.flat_map(&shape(&1, {5, 5}))
      |> Stream.zip(Stream.cycle(@alignment_pattern))
      |> Enum.reduce(matrix, fn {coordinate, v}, acc ->
        update(acc, coordinate, v)
      end)

    %{m | matrix: matrix}
  end

  @doc """
  Draw the timing patterns.
  """
  @spec draw_timing_patterns(t) :: t
  def draw_timing_patterns(%__MODULE__{matrix: matrix, modules: modules} = m) do
    z = modules - 13

    matrix =
      [{z, 1}, {1, z}]
      |> Stream.flat_map(&shape({6, 6}, &1))
      |> Stream.zip(Stream.cycle([1, 0]))
      |> Enum.reduce(matrix, fn {coordinate, v}, acc ->
        update(acc, coordinate, v)
      end)

    %{m | matrix: matrix}
  end

  @doc """
  Draw the dark module.
  """
  @spec draw_dark_module(t) :: t
  def draw_dark_module(%__MODULE__{matrix: matrix, modules: modules} = m) do
    matrix = update(matrix, {modules - 8, 8}, 1)
    %{m | matrix: matrix}
  end

  @doc """
  Draw the reserved format information areas.
  """
  @spec draw_reserved_format_areas(t) :: t
  def draw_reserved_format_areas(%__MODULE__{matrix: matrix, modules: modules} = m) do
    z = modules - 8

    matrix =
      [{{0, 8}, {1, 9}}, {{z, 8}, {1, 8}}, {{8, 0}, {9, 1}}, {{8, z}, {8, 1}}]
      |> Stream.flat_map(fn {a, b} -> shape(a, b) end)
      |> Enum.reduce(matrix, &update(&2, &1, :reserved))

    %{m | matrix: matrix}
  end

  @doc """
  Draw the reserved version information areas.
  """
  @spec draw_reserved_version_areas(t) :: t
  def draw_reserved_version_areas(%__MODULE__{version: version} = m) when version < 7, do: m

  def draw_reserved_version_areas(%__MODULE__{matrix: matrix, modules: modules} = m) do
    z = modules - 11

    matrix =
      [{{0, z}, {3, 6}}, {{z, 0}, {6, 3}}]
      |> Stream.flat_map(fn {a, b} -> shape(a, b) end)
      |> Enum.reduce(matrix, &update(&2, &1, :reserved))

    %{m | matrix: matrix}
  end

  @doc """
  Draw the data bits with mask.
  """
  @spec draw_data_with_mask(t, binary) :: t
  def draw_data_with_mask(%__MODULE__{matrix: matrix, modules: modules} = m, data) do
    candidate =
      Stream.unfold(modules - 1, fn
        -1 -> nil
        8 -> {8, 5}
        n -> {n, n - 2}
      end)
      |> Stream.zip(Stream.cycle([:up, :down]))
      |> Stream.flat_map(fn {z, path} -> path(path, {modules - 1, z}) end)
      |> Stream.filter(&available?(matrix, &1))
      |> Stream.zip(EQRCode.Encode.bits(data))

    {mask, _, matrix} =
      Stream.map(0b000..0b111, fn mask ->
        matrix =
          Enum.reduce(candidate, matrix, fn {coordinate, v}, acc ->
            update(acc, coordinate, v ^^^ EQRCode.Mask.mask(mask, coordinate))
          end)

        {mask, EQRCode.Mask.score(matrix), matrix}
      end)
      |> Enum.min_by(&elem(&1, 1))

    %{m | matrix: matrix, mask: mask}
  end

  @doc """
  Draw the data bits with mask 0.
  """
  @spec draw_data_with_mask0(t, binary) :: t
  def draw_data_with_mask0(%__MODULE__{matrix: matrix, modules: modules} = m, data) do
    matrix =
      Stream.unfold(modules - 1, fn
        -1 -> nil
        8 -> {8, 5}
        n -> {n, n - 2}
      end)
      |> Stream.zip(Stream.cycle([:up, :down]))
      |> Stream.flat_map(fn {z, path} -> path(path, {modules - 1, z}) end)
      |> Stream.filter(&available?(matrix, &1))
      |> Stream.zip(EQRCode.Encode.bits(data))
      |> Enum.reduce(matrix, fn {coordinate, v}, acc ->
        update(acc, coordinate, v ^^^ EQRCode.Mask.mask(0, coordinate))
      end)

    %{m | matrix: matrix, mask: 0}
  end

  defp path(:up, {x, y}),
    do:
      for(
        i <- x..0,
        j <- y..(y - 1),
        do: {i, j}
      )

  defp path(:down, {x, y}),
    do:
      for(
        i <- 0..x,
        j <- y..(y - 1),
        do: {i, j}
      )

  @doc """
  Fill the reserved format information areas.
  """
  @spec draw_format_areas(t) :: t
  def draw_format_areas(
        %__MODULE__{matrix: matrix, modules: modules, mask: mask, error_correction_level: ecl} = m
      ) do
    ecc_l = SpecTable.error_corretion_bits(ecl)
    data = EQRCode.ReedSolomon.bch_encode(<<ecc_l::2, mask::3>>)

    matrix =
      [
        {{8, 0}, {9, 1}},
        {{7, 8}, {1, -6}},
        {{modules - 1, 8}, {1, -6}},
        {{8, modules - 8}, {8, 1}}
      ]
      |> Stream.flat_map(fn {a, b} -> shape(a, b) end)
      |> Stream.filter(&reserved?(matrix, &1))
      |> Stream.zip(Stream.cycle(data))
      |> Enum.reduce(matrix, fn {coordinate, v}, acc ->
        put(acc, coordinate, v)
      end)

    %{m | matrix: matrix}
  end

  @doc """
  Fill the reserved version information areas.
  """
  @spec draw_version_areas(t) :: t
  def draw_version_areas(%__MODULE__{version: version} = m) when version < 7, do: m

  def draw_version_areas(%__MODULE__{matrix: matrix, modules: modules, version: version} = m) do
    version_information_bits = SpecTable.version_information_bits(version)
    data = EQRCode.Encode.bits(<<version_information_bits::18>>)
    z = modules - 9

    matrix =
      [
        {{z, 5}, {1, -1}},
        {{z, 4}, {1, -1}},
        {{z, 3}, {1, -1}},
        {{z, 2}, {1, -1}},
        {{z, 1}, {1, -1}},
        {{z, 0}, {1, -1}},
        {{5, z}, {-1, 1}},
        {{4, z}, {-1, 1}},
        {{3, z}, {-1, 1}},
        {{2, z}, {-1, 1}},
        {{1, z}, {-1, 1}},
        {{0, z}, {-1, 1}}
      ]
      |> Stream.flat_map(fn {a, b} -> shape(a, b) end)
      |> Stream.filter(&reserved?(matrix, &1))
      |> Stream.zip(Stream.cycle(data))
      |> Enum.reduce(matrix, fn {coordinate, v}, acc ->
        put(acc, coordinate, v)
      end)

    %{m | matrix: matrix}
  end

  defp reserved?(matrix, {x, y}) do
    get_in(matrix, [Access.elem(x), Access.elem(y)]) == :reserved
  end

  defp put(matrix, {x, y}, value) do
    put_in(matrix, [Access.elem(x), Access.elem(y)], value)
  end

  @doc """
  Draw the quite zone.
  """
  @spec draw_quite_zone(t) :: t
  def draw_quite_zone(%__MODULE__{matrix: matrix, modules: modules} = m) do
    zone = Tuple.duplicate(0, modules + 4)

    matrix =
      Enum.reduce(0..(modules - 1), matrix, fn i, acc ->
        update_in(acc, [Access.elem(i)], fn row ->
          Tuple.insert_at(row, 0, 0)
          |> Tuple.insert_at(0, 0)
          |> Tuple.append(0)
          |> Tuple.append(0)
        end)
      end)
      |> Tuple.insert_at(0, zone)
      |> Tuple.insert_at(0, zone)
      |> Tuple.append(zone)
      |> Tuple.append(zone)

    %{m | matrix: matrix}
  end

  @doc """
  Given the starting point {x, y} and {width, height}
  returns the coordinates of the shape.

  ## Examples

      iex> EQRCode.Matrix.shape({0, 0}, {3, 3})
      [{0, 0}, {0, 1}, {0, 2},
       {1, 0}, {1, 1}, {1, 2},
       {2, 0}, {2, 1}, {2, 2}]

  """
  @spec shape(coordinate, {integer, integer}) :: [coordinate]
  def shape({x, y}, {w, h}) do
    for i <- x..(x + h - 1),
        j <- y..(y + w - 1),
        do: {i, j}
  end

  defp update(matrix, {x, y}, value) do
    update_in(matrix, [Access.elem(x), Access.elem(y)], fn
      nil -> value
      val -> val
    end)
  end

  defp available?(matrix, {x, y}) do
    get_in(matrix, [Access.elem(x), Access.elem(y)]) == nil
  end

  @doc """
  Get matrix size.
  """
  @spec size(t()) :: integer()
  def size(%__MODULE__{matrix: matrix}) do
    matrix |> Tuple.to_list() |> Enum.count()
  end
end
