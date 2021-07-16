defmodule EQRCode.Alphanumeric do

  # Encoding table sourced from: https://www.thonky.com/qr-code-tutorial/alphanumeric-table
  @lookup_table %{
    ?0 => 0,
    ?1 => 1,
    ?2 => 2,
    ?3 => 3,
    ?4 => 4,
    ?5 => 5,
    ?6 => 6,
    ?7 => 7,
    ?8 => 8,
    ?9 => 9,
    ?A => 10,
    ?B => 11,
    ?C => 12,
    ?D => 13,
    ?E => 14,
    ?F => 15,
    ?G => 16,
    ?H => 17,
    ?I => 18,
    ?J => 19,
    ?K => 20,
    ?L => 21,
    ?M => 22,
    ?N => 23,
    ?O => 24,
    ?P => 25,
    ?Q => 26,
    ?R => 27,
    ?S => 28,
    ?T => 29,
    ?U => 30,
    ?V => 31,
    ?W => 32,
    ?X => 33,
    ?Y => 34,
    ?Z => 35,
    32 => 36,
    ?$ => 37,
    ?% => 38,
    ?* => 39,
    ?+ => 40,
    ?- => 41,
    ?. => 42,
    ?/ => 43,
    ?: => 44,
  }

  @spec from_binary(binary()) :: binary()
  def from_binary(<<one, two, rest::binary>>) do
    value = (45 * @lookup_table[one]) + @lookup_table[two]
    <<value::11, from_binary(rest)::bitstring >>
  end

  def from_binary(<<one>>), do: <<@lookup_table[one]::6>>
  def from_binary(<<>>), do: <<>>
end
