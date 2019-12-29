defmodule HackAssembler.Code do
  alias HackAssembler.Parser

  @spec encode(list(Parser.instruction()), map()) :: String.t()
  def encode(instructions, symbol_table) do
    instructions
    |> Enum.reduce("", fn
      {:l, _}, acc ->
        acc

      {:a, l}, acc ->
        addr =
          case Integer.parse(l) do
            {addr, ""} ->
              addr

            _ ->
              Map.get(symbol_table, l)
          end

        acc <> String.pad_leading(Integer.to_string(addr, 2), 16, "0") <> "\n"

      {:c, _} = c_instruction, acc ->
        acc <> c_instruction_to_machine_code(c_instruction) <> "\n"
    end)
  end

  defp c_instruction_to_machine_code({:c, %{comp: comp, dest: dest, jump: jump}}) do
    "111" <> encode_comp(comp) <> encode_dest(dest) <> encode_jump(jump)
  end

  defp encode_comp(comp) do
    case comp do
      nil ->
        "0000000"

      "0" ->
        "0101010"

      "1" ->
        "0111111"

      "-1" ->
        "0111010"

      "D" ->
        "0001100"

      "A" ->
        "0110000"

      "!D" ->
        "0001101"

      "!A" ->
        "0110001"

      "-D" ->
        "0001111"

      "-A" ->
        "0110011"

      "D+1" ->
        "0011111"

      "A+1" ->
        "0110111"

      "D-1" ->
        "0001110"

      "A-1" ->
        "0110010"

      "D+A" ->
        "0000010"

      "D-A" ->
        "0010011"

      "A-D" ->
        "0000111"

      "D&A" ->
        "0000000"

      "D|A" ->
        "0010101"

      "M" ->
        "1110000"

      "!M" ->
        "1110001"

      "-M" ->
        "1110011"

      "M+1" ->
        "1110111"

      "M-1" ->
        "1110010"

      "D+M" ->
        "1000010"

      "D-M" ->
        "1010011"

      "M-D" ->
        "1000111"

      "D&M" ->
        "1000000"

      "D|M" ->
        "1010101"
    end
  end

  defp encode_dest(dest) do
    case dest do
      nil ->
        "000"

      "M" ->
        "001"

      "D" ->
        "010"

      "MD" ->
        "011"

      "A" ->
        "100"

      "AM" ->
        "101"

      "AD" ->
        "110"

      "AMD" ->
        "111"
    end
  end

  defp encode_jump(jump) do
    case jump do
      nil ->
        "000"

      "JGT" ->
        "001"

      "JEQ" ->
        "010"

      "JGE" ->
        "011"

      "JLT" ->
        "100"

      "JNE" ->
        "101"

      "JLE" ->
        "110"

      "JMP" ->
        "111"
    end
  end
end
