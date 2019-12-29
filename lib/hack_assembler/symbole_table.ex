defmodule HackAssembler.SymbolTable do
  alias HackAssembler.Parser

  @preset_symbols %{
    "SP" => 0,
    "LCL" => 1,
    "ARG" => 2,
    "THIS" => 3,
    "THAT" => 4,
    "R0" => 0,
    "R1" => 1,
    "R2" => 2,
    "R3" => 3,
    "R4" => 4,
    "R5" => 5,
    "R6" => 6,
    "R7" => 7,
    "R8" => 8,
    "R9" => 9,
    "R10" => 10,
    "R11" => 11,
    "R12" => 12,
    "R13" => 13,
    "R14" => 14,
    "R15" => 15,
    "SCREEN" => 16384,
    "KDB" => 24576
  }

  @spec build(list(Parser.instruction())) :: map()
  def build(instructions) do
    %{symbol_table: symbol_table, var_symbols: var_symbols} =
      instructions
      |> Enum.reduce(
        %{next_line_num: 0, symbol_table: @preset_symbols, var_symbols: []},
        fn
          {:c, _}, acc ->
            %{acc | next_line_num: acc.next_line_num + 1}

          {:a, addr}, acc ->
            case Integer.parse(addr) do
              :error ->
                case Enum.member?(acc.var_symbols, addr) do
                  false ->
                    acc
                    |> Map.put(:var_symbols, [addr | acc.var_symbols])

                  true ->
                    acc
                end

              _ ->
                acc
            end
            |> Map.put(:next_line_num, acc.next_line_num + 1)

          {:l, label}, acc ->
            case Map.get(acc.symbol_table, label) do
              nil ->
                acc
                |> Map.update!(:symbol_table, &Map.put(&1, label, acc.next_line_num))

              _ ->
                acc
            end
        end
      )

    var_symbols
    |> Enum.reverse()
    |> Enum.reduce(%{symbol_table: symbol_table, next_addr_val: 16}, fn var, acc ->
      case Map.get(acc.symbol_table, var) do
        nil ->
          %{
            acc
            | symbol_table: Map.put(acc.symbol_table, var, acc.next_addr_val),
              next_addr_val: acc.next_addr_val + 1
          }

        _ ->
          acc
      end
    end)
    |> Map.get(:symbol_table)
  end
end
