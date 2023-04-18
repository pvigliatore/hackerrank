defmodule Solution do
  @after_compile __MODULE__

  def __after_compile__(_, _) do
    # Read the input 
    current_pos = read_coord()
    {height, _width} = read_coord()

    0..(height - 1)
    |> Stream.flat_map(&read_row_data(&1))
    |> Enum.sort_by(&offset(current_pos, &1))
    |> Enum.take(1)
    |> Enum.map(&next_move/1)
    |> IO.puts()
  end

  def read_coord do
    IO.read(:line)
    |> String.trim()
    |> String.split()
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  def read_row_data(row, data \\ nil) do
    data ||
      IO.read(:line)
      |> String.trim()
      |> String.codepoints()
      |> Stream.with_index()
      |> Stream.filter(fn {status, _} -> status == "d" end)
      |> Enum.map(fn {_, col} -> {row, col} end)
  end

  def offset({m_row, m_col}, {d_row, d_col}) do
    vertical_distance = d_row - m_row
    horizontal_distance = d_col - m_col
    total_distance = abs(vertical_distance) + abs(horizontal_distance)
    {total_distance, vertical_distance, horizontal_distance}
  end

  def next_move({0, 0}), do: "CLEAN"
  def next_move({row, _}) when row < 0, do: "UP"
  def next_move({row, _}) when row > 0, do: "DOWN"
  def next_move({_, col}) when col < 0, do: "LEFT"
  def next_move({_, col}) when col > 0, do: "RIGHT"
end
