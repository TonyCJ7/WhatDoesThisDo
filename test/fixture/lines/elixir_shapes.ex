defmodule ExConfig do
  @ex_limit 3

  def run, do: @ex_limit + ex_attempt(1)

  defp ex_attempt(n), do: n
end

IO.puts(ExConfig.run())
