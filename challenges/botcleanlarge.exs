defmodule Solution do
  @after_compile __MODULE__

  def __after_compile__(_, _) do
    # Read the input 
    current_pos = read_coord()
    {height, _width} = read_coord()

    0..(height - 1)
    |> Stream.flat_map(&read_row_data(&1))
    |> Enum.min_by(&distance(current_pos, &1))
    |> next_move(current_pos)
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

  def distance({m_row, m_col}, {d_row, d_col}) do
    vertical_distance = d_row - m_row
    horizontal_distance = d_col - m_col
    total_distance = abs(vertical_distance) + abs(horizontal_distance)
    {total_distance, vertical_distance, horizontal_distance}
  end

  def next_move(d_pos, m_pos) when d_pos == m_pos, do: "CLEAN"
  def next_move({d_row, _}, {m_row, _}) when m_row > d_row, do: "UP"
  def next_move({d_row, _}, {m_row, _}) when m_row < d_row, do: "DOWN"
  def next_move({_, d_col}, {_, m_col}) when m_col > d_col, do: "LEFT"
  def next_move({_, d_col}, {_, m_col}) when m_col < d_col, do: "RIGHT"
end
