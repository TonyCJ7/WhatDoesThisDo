defmodule ExTwins do
  def run, do: ex_twin(1) + ex_twin(1, 2)

  def ex_twin(n), do: n

  def ex_twin(n, m), do: n + m
end
