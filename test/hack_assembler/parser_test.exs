defmodule HackAssembler.ParserTest do
  use ExUnit.Case
  doctest HackAssembler.Parser

  alias HackAssembler.Parser

  describe "parse_instruction/1" do
    test "parse a instruction with address" do
      assert {:ok, {:a, "1"}} == Parser.parse_instruction("@1")
    end

    test "parse a instruction with symbol" do
      assert {:ok, {:a, "a"}} == Parser.parse_instruction("@a")
    end

    test "parse a instruction without address or symbol" do
      assert {:error, _} = Parser.parse_instruction("@")
    end

    test "parse a instruction with invalid symbol character" do
      assert {:error, _} = Parser.parse_instruction("@@")
    end

    test "parse l instruction with valid symbol character" do
      assert {:ok, {:l, "A"}} == Parser.parse_instruction("(A)")
      assert {:ok, {:l, "A:B_c"}} == Parser.parse_instruction("(A:B_c)")
    end

    test "parse l instruction with invalid symbol character" do
      assert {:error, _} = Parser.parse_instruction("(A@)")
    end

    test "parse c instruction with only jump" do
      assert {:error, _} = Parser.parse_instruction("JMP")
    end

    test "parse c instruction with only comp" do
      assert {:error, _} = Parser.parse_instruction("0")
      assert {:error, _} = Parser.parse_instruction("D-A")
    end

    test "parse c instruction with empty assginment" do
      assert {:error, _} = Parser.parse_instruction("D=")
    end

    test "parse c instruction with valid dest and comp" do
      assert {:ok, {:c, %{comp: "0", dest: "D", jump: nil}}} == Parser.parse_instruction("D=0")

      assert {:ok, {:c, %{comp: "D|A", dest: "AMD", jump: nil}}} ==
               Parser.parse_instruction("AMD=D|A")
    end

    test "parse c instruction with valid comp and jump" do
      assert {:ok, {:c, %{comp: "0", dest: nil, jump: "JMP"}}} ==
               Parser.parse_instruction("0;JMP")

      assert {:ok, {:c, %{comp: "D+A", dest: nil, jump: "JGT"}}} ==
               Parser.parse_instruction("D+A;JGT")
    end

    test "parse c instruction with valid dest, comp and jump" do
      assert {:ok, {:c, %{comp: "0", dest: "M", jump: "JMP"}}} ==
               Parser.parse_instruction("M=0;JMP")

      assert {:ok, {:c, %{comp: "D-A", dest: "AMD", jump: "JLT"}}} ==
               Parser.parse_instruction("AMD=D-A;JLT")
    end
  end

  #  describe "parse/1" do
  #    test "successfully parse multi-line valid instruction" do
  #      assert {:ok, [
  #        %{}
  #      ]} == Parser.parse("""
  #      """)
  #    end
  #  end
end
