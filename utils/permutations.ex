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
