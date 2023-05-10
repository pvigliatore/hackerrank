defmodule Solution do
  @after_compile __MODULE__

  def __after_compile__(_, _), do: run()

  def run() do
    current_pos = read_coord()

    read_board()
    |> find_dirt()
    |> next_move(current_pos)
    |> IO.puts()
  end

  defp read_coord do
    IO.read(:line)
    |> String.trim()
    |> String.split()
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  @spec read_board(integer()) :: %{tuple() => String.t()}
  defp read_board(height \\ 5) do
    0..(height - 1)
    |> Stream.flat_map(&read_row_data(&1))
    |> Map.new()
  end

  defp read_row_data(row) do
    IO.read(:line)
    |> String.trim()
    |> String.codepoints()
    |> Stream.with_index()
    |> Enum.map(fn {status, col} -> {{row, col}, status} end)
  end

  defp find_dirt(board) do
    board
    |> Enum.filter(fn {_coord, status} -> status == "d" end)
    |> Enum.map(&elem(&1, 0))
  end

  defp patrol, do: [{1, 1}, {2, 1}, {3, 1}, {3, 2}, {3, 3}, {2, 3}, {1, 3}, {1, 2}]
  defp on_patrol?(pos), do: pos in patrol()

  defp next_patrol(pos) do
    patrol()
    |> Stream.cycle()
    |> Stream.drop_while(&(&1 != pos))
    |> Stream.drop(1)
    |> Enum.take(1)
    |> hd()
    |> next_move(pos)
  end

  defp back_to_patrol({2, 2}), do: "LEFT"
  defp back_to_patrol({0, _}), do: "DOWN"
  defp back_to_patrol({4, _}), do: "UP"
  defp back_to_patrol({_, 0}), do: "RIGHT"
  defp back_to_patrol({_, 4}), do: "LEFT"

  # Patrol an inner circle which gains visibility to all squares
  #   - Approach and clean the closest dirt wherever it is, prefer left and down over right and up
  #   - Once dirt is clean, return to the patrol route
  def next_move(dirts, pos)

  # there's no dirt, keep moving along the circuit
  def next_move([], pos) do
    if on_patrol?(pos),
      do: next_patrol(pos),
      else: back_to_patrol(pos)
  end

  # There's at least one dirt
  def next_move(dirts, m_pos) when is_list(dirts) do
    dirts
    |> Enum.min_by(&distance(m_pos, &1))
    |> next_move(m_pos)
  end

  # there's 1 dirt, go get it!
  def next_move(d_pos, m_pos) when d_pos == m_pos, do: "CLEAN"
  def next_move({_, d_col}, {_, m_col}) when m_col > d_col, do: "LEFT"
  def next_move({d_row, _}, {m_row, _}) when m_row < d_row, do: "DOWN"
  def next_move({_, d_col}, {_, m_col}) when m_col < d_col, do: "RIGHT"
  def next_move({d_row, _}, {m_row, _}) when m_row > d_row, do: "UP"

  def distance({start_row, start_col}, {target_row, target_col}) do
    vertical_distance = target_row - start_row
    horizontal_distance = target_col - start_col
    total_distance = abs(vertical_distance) + abs(horizontal_distance)
    {total_distance, horizontal_distance, vertical_distance}
  end
end

