defmodule Gpixir do
  @moduledoc "A genetic programming library for Elixir"
  import IO, only: [puts: 1]
  import Enum, only: [count: 1, map: 2, into: 2, take: 2, zip: 2, random: 1, to_list: 1]
  import Stream, only: [concat: 2]
  import Gpixir.Util
  @function_table zip(["and", "or", "nand", "nor", "not"],
                      [&p_and/2, &p_or/2, &nand/2, &nor/2, &not/1])

  @target_data [[false, false, false, true],
               [false, false, true, false],
               [false, true, false, false],
               [false, true, true, true],
               [true, false, false, false],
               [true, false, true, true],
               [true, true, false, true],
               [true, true, true, false]]

  def random_function do
    @function_table |> Dict.values |> random
  end

  def random_terminal do
    random([fn(in1, _, _) -> in1 end,
            fn(_, in2, _) -> in2 end,
            fn(_, _, in3) -> in3 end])
  end

  def random_code(depth) do
    if (depth == 0) or (:rand.uniform(2) == 1) do
      # puts "Depth: #{depth}"
      random_terminal
    else
      f = random_function
      # puts "Depth: #{depth}, Arity: #{arity f}"
      # puts Macro.to_string(f)
      # puts "Arity: #{arity(f)}"
      # USE MACROS AND QUOTING/THE AST INSTEAD OF NESTED CALLS
      f.(repeatedly(fn() -> random_code(depth - 1) end, arity(f)))
      # Stream.map(&(repeatedly(fn() -> random_code(depth - 1) end) |> Stream.take(arity(&1))), f)
      # Stream.concat([f], repeatedly(fn() -> random_code(depth - 1) end) |> take(arity(f)))
    end
  end

  def error(individual) do
    puts "Individual: #{Macro.to_string individual}"
    puts "Getting error..."
    value_function = fn(in1, in2, in3) -> individual.([in1, in2, in3]) end
    puts "Value function: #{Macro.to_string value_function}"
    s = @target_data |> map(fn([in1, in2, in3, correct_output]) ->
      if(individual.(in1, in2, in3) == correct_output) do
        puts "Inserting 0"
        0
      else
        puts "Inserting 1"
        1
      end
    end) |> sum_list
    puts Macro.to_string s
    s
  end

  def codesize(c) do
    puts "Getting codesize..."
    puts Macro.to_string(c)
    String.length(Macro.to_string(c))
  end

  def random_subtree(i) do
    if :rand.uniform(codesize(i) + 1) == 1 do
      puts "The thing is: #{Macro.to_string(i)}"
      i
    else
      tl(i) |> map(fn(a) -> repeatedly(a, codesize(a)) end)
            |> List.flatten
            |> random
            |> random_subtree
      # random_subtree(Enum.random(List.flatten([Stream.map(tl(i), fn(a) -> repeatedly(a, codesize(a)) end)])))
    end
  end

  def replace_random_subtree(i, replacement) do
    if :rand.uniform(codesize(i) + 1) == 1 do
      replacement
    else
      # zipped = Enum.zip(tl(i), one_to_inf)
      # puts "The thing: #{Macro.to_string(zipped)}"
      position_to_change = zip(tl(i), one_to_inf)
                           |> map(fn{a, b} -> repeat(codesize(a), b) end)
                           |> Stream.concat
                           |> random
      map(zip(for(n <- zero_to_inf, do: n == position_to_change), i), fn{a, b} ->
          if a do
            replace_random_subtree(b, replacement)
          else
            b
          end
        end)
    end
  end

  def mutate(i) do
    puts "Mutating!!"
    replace_random_subtree(i, random_code(2))
  end

  def crossover(i, j) do
    puts "Crossing over!!"
    replace_random_subtree(i, random_subtree(j))
  end

  def sort_by_error(population) do
    puts "Sorting #{Macro.to_string population} by error..."
    errors = population |> map(&(Enum.concat([error(&1)], [&1])))
    puts "Got errors!!"
    puts Macro.to_string errors
    es = into([], errors
                  |> Enum.sort(fn([err1, _], [err2, _]) -> err1 < err2 end)
                  |> map(&second/1))
    puts Macro.to_string es
    es
  end

  def select(population, tournament_size) do
    puts "Selecting!!"
    size = count(population)
    Enum.fetch(population, repeat(:rand.uniform(size), tournament_size)
                           |> to_list
                           |> Enum.min)
  end

  def evolve_sub(generation, population, size) do
    best = hd(population)
    best_error = error(best)
    puts "======================"
    puts "Generation: #{generation}"
    puts "Best error: #{best_error}"
    puts "Best program: #{Macro.to_string best}"
    puts "Median error: #{error(Enum.fetch!(population, div(size, 2)))}"
    puts "Average program size: #{Macro.to_string((population |> map(&codesize/1) |> sum_list) / count(population))}"
    if best_error < 100.1 do
      puts "Success: #{Macro.to_string best}"
      # puts "Success: #{Macro.to_string(Macro.expand(best, __ENV__))}"
    else
      mutated = repeatedly(mutate(select(population, 5)), round(size * 0.05))
      crossed_over = repeatedly(crossover(select(population, 5), select(population, 5)), round(size * 0.8))
      mut_and_cross = concat(mutated, crossed_over)
      selected = repeatedly(fn() -> select(population, 5) end, round(size * 0.1))
      to_be_sorted = mut_and_cross |> concat(selected) |> to_list |> sort_by_error
      evolve_sub(generation + 1, to_be_sorted, size)
    end
  end

  def evolve(popsize) do
    puts "Starting evolution..."
    will_sort = to_list(repeatedly(fn() -> random_code(2) end, popsize))
    evolve_sub(0, sort_by_error(will_sort), popsize)
  end
end
