defmodule Solution do
  @after_compile __MODULE__

  def __after_compile__(_, _) do
    # Read the input 
    size = IO.read(:line) |> String.trim() |> String.to_integer()

    [row, column] =
      IO.read(:line)
      |> String.trim()
      |> String.split()
      |> Enum.map(&String.to_integer/1)

    board =
      Range.new(0, size - 1)
      |> Stream.map(fn _i -> IO.read(:line) end)
      |> Stream.map(&String.trim/1)
      |> Enum.reduce(fn row, acc -> acc <> row end)

    princess_index = board |> String.split("p") |> hd() |> String.length()
    princess_position = {div(princess_index, size), rem(princess_index, size)}
    IO.puts(next_move(size, {row, column}, princess_position))
  end

  def next_move(_, {mario_row, _}, {princess_row, _}) when mario_row < princess_row, do: "DOWN"
  def next_move(_, {mario_row, _}, {princess_row, _}) when mario_row > princess_row, do: "UP"
  def next_move(_, {_, mario_col}, {_, princess_col}) when mario_col < princess_col, do: "RIGHT"
  def next_move(_, {_, mario_col}, {_, princess_col}) when mario_col > princess_col, do: "LEFT"
end
