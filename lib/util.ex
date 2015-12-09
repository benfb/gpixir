defmodule Gp.Util do
  @moduledoc "Utility functions for a genetic programming library for Elixir"
  # def repeatedly(f, n) do
  #   Stream.repeatedly(f) |> Enum.take(n)
  # end

  # from http://stackoverflow.com/a/28700529
  def sum_list(list), do: Enum.reduce(list, 0, &(&1 + &2))

  def arity(f), do: Dict.get(:erlang.fun_info(f), :arity)

  def second(t) do
    t |> tl |> hd
  end

  def p_and(a, b) do
    a && b
  end

  def p_or(a, b) do
    a || b
  end

  def nand(a, b) do
    !p_and(a, b)
  end

  def nor(a, b) do
    !p_or(a, b)
  end

  def zero_to_inf do
    Stream.iterate(0, &(&1+1))
  end

  def one_to_inf do
    Stream.iterate(1, &(&1+1))
  end
end
