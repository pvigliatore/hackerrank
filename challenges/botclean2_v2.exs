defmodule Solution do
  @filename "bolclean2_v2.game_state"

  def run() do
    current_cell = read_coord()
    board = Board.merge_board(restore_state(), read_board())
    save_state(board)

    [^current_cell, next_cell] =
      board
      |> Pathfinder.shortest_path(current_cell)
      |> Enum.take(2)

    action =
      if Board.dirty?(board, current_cell),
        do: "CLEAN",
        else: move_to(current_cell, next_cell)

    IO.puts(action)
  end

  defp read_coord(io_dev \\ :stdio) do
    IO.read(io_dev, :line)
    |> String.trim()
    |> String.split()
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  def read_board(io_dev \\ :stdio, height \\ 5) do
    0..(height - 1)
    |> Stream.flat_map(&read_row_data(io_dev, &1))
    |> Map.new()
  end

  defp read_row_data(io_dev, row) do
    IO.read(io_dev, :line)
    |> String.trim()
    |> String.codepoints()
    |> Stream.map(&normalize_cell_status/1)
    |> Stream.with_index()
    |> Enum.map(fn {status, col} -> {{row, col}, status} end)
  end

  # The placement of the bot doesn't matter, ignore it
  defp normalize_cell_status(status), do: String.replace(status, "b", "-")

  def save_state(board) do
    File.open!(@filename, [:write, :utf8], fn io_dev ->
      Board.print_board(io_dev, board)
    end)
  end

  def restore_state() do
    if File.exists?(@filename),
      do: File.open!(@filename, [:read, :utf8], &read_board/1),
      else: Board.empty()
  end

  def move_to({_, from_col}, {_, to_col}) when from_col > to_col, do: "LEFT"
  def move_to({from_row, _}, {to_row, _}) when from_row < to_row, do: "DOWN"
  def move_to({_, from_col}, {_, to_col}) when from_col < to_col, do: "RIGHT"
  def move_to({from_row, _}, {to_row, _}) when from_row > to_row, do: "UP"
end

defmodule Board do
  @moduledoc """
  A board that must be cleaned
  """

  @type cell :: {integer(), integer()}
  @type t() :: %{cell() => String.t()}

  def empty() do
    coords = for row <- 0..4, col <- 0..4, do: {row, col}
    Map.new(coords, &{&1, "o"})
  end

  def merge_board(previous, current) do
    Map.merge(previous, current, fn
      _coord, old, "o" -> old
      _coord, _old, new -> new
    end)
  end

  def print_board(io_dev \\ :stdio, board) do
    coords = for row <- 0..4, col <- 0..4, do: {row, col}

    coords
    |> Stream.map(&Map.fetch!(board, &1))
    |> Stream.chunk_every(5)
    |> Stream.map(&Enum.join/1)
    |> Enum.each(&IO.puts(io_dev, &1))
  end

  def discover(board, {row, col}) do
    coords =
      for r <- Range.new(row - 1, row + 1),
          c <- Range.new(col - 1, col + 1),
          valid_coord?({r, c}) do
        {r, c}
      end

    coords
    |> Map.new(&{&1, "-"})
    |> Enum.into(board)
  end

  def discover(board, cells) do
    Enum.reduce(cells, board, &discover(&2, &1))
  end

  def surrounding_coords({row, col}) do
    # find up to 8 coords surrounding the given coord
    for next_row <- Range.new(row - 1, row + 1),
        next_col <- Range.new(col - 1, col + 1),
        valid_coord?({next_row, next_col}) and {next_row, next_col} != {row, col} do
      {next_row, next_col}
    end
  end

  def undiscovered_neighbors(board, coord) do
    coord
    |> surrounding_coords()
    |> Enum.count(&undiscovered?(board, &1))
  end

  def dirty?(board, coord), do: board[coord] == "d"

  defp valid_coord?({row, col}), do: row in 0..4 and col in 0..4
  defp undiscovered?(board, coord), do: board[coord] == "o"

  def undiscovered_cells(board), do: filter_by_status(board, "o")
  def dirty_cells(board), do: filter_by_status(board, "d")

  defp filter_by_status(board, value) do
    board
    |> Enum.filter(fn {_coord, status} -> status == value end)
    |> Map.new()
    |> Map.keys()
  end

  @doc """
  Identify the minimum set of cells that must be visited in order to discover
  all undidscovered cells and clean all known dirty cells
  """
  def points_of_interest(board) do
    dirty_cells = dirty_cells(board)
    after_visiting_dirty_cells = discover(board, dirty_cells)
    vantage_points = vantage_points(after_visiting_dirty_cells)
    Enum.concat(dirty_cells, vantage_points)
  end

  defp vantage_point(board) do
    # Return a cell that provides the greatest visibility, that is, a cell that will discover the
    # most undiscovered adjacent cells
    case undiscovered_cells(board) do
      [] -> nil
      cells -> Enum.max_by(cells, &undiscovered_neighbors(board, &1), fn -> nil end)
    end
  end

  @doc """
  Returns a set of vantage points that would allow the discovery of all remaining undiscovered cells.
  """
  def vantage_points(board) do
    board
    |> Stream.unfold(fn next_board ->
      case vantage_point(next_board) do
        nil -> nil
        cell -> {cell, discover(next_board, cell)}
      end
    end)
    |> Enum.to_list()
  end
end

defmodule Pathfinder do
  @moduledoc """
  A pathfinding algorithm that will ensure all undiscovered areas are found
  and all dirty cells are visited
  """
  def shortest_path(board, start_cell) do
    board
    |> Board.points_of_interest()
    |> Permutations.naive()
    |> Enum.map(&[start_cell | &1])
    |> Enum.min_by(&total_distance/1)
  end

  def total_distance(waypoints) do
    [waypoints, tl(waypoints)]
    |> Enum.zip()
    |> Enum.map(fn {from, to} -> distance(from, to) end)
    |> Enum.sum()
  end

  def distance(from, to) do
    {froto_row, froto_col} = from
    {to_row, to_col} = to
    abs(froto_row - to_row) + abs(froto_col - to_col)
  end
end

defmodule Permutations do
  def naive(values) when is_list(values) do
    []
    |> expand(values)
    |> next(length(values) - 1)
  end

  def next(permutations, remaining) do
    if remaining == 0 do
      Enum.map(permutations, fn {permutation, _} -> permutation end)
    else
      permutations
      |> Enum.flat_map(fn {permutation, remaining} -> expand(permutation, remaining) end)
      |> next(remaining - 1)
    end
  end

  defp expand(permutation, remaining_values) do
    Enum.map(remaining_values, &{[&1 | permutation], remaining_values -- [&1]})
  end
end

Solution.run()
