defmodule HackAssembler.SymbolTableTest do
  use ExUnit.Case
  doctest HackAssembler.SymbolTable

  alias HackAssembler.SymbolTable

  describe "parse_instruction/1" do
    test "parse a instruction with address" do
      symbol_table =
        SymbolTable.build([
          {:a, "i"},
          {:c, %{dest: "M", comp: "D+1"}},
          {:l, "LOOP"},
          {:a, "LOOP"},
          {:c, %{dest: nil, comp: "1", jump: "JGT"}}
        ])

      assert Map.get(symbol_table, "i") == 16
      assert Map.get(symbol_table, "LOOP") == 2
    end
  end
end
