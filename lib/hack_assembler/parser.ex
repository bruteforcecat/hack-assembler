defmodule HackAssembler.Parser do
  @type instruction ::
          {:a, String.t()}
          | {:c, %{dest: String.t() | nil, comp: String.t(), jump: String.t() | nil}}
          | {:l, String.t()}

  @spec parse(String.t()) :: {:ok, list(instruction)} | {:error, String.t()}
  def parse(machine_code_str) do
    machine_code_str
    |> String.split("\n")
    |> do_parse([])
  end

  defp do_parse([], instructions) do
    {:ok, instructions}
  end

  # use recursion instead of reduce to allow "short-circuit"
  defp do_parse([code_line | code_lines], instructions) do
    case parse_instruction(code_line) do
      {:ok, instruction} ->
        do_parse(code_lines, [instruction | instructions])

      {:error, _} ->
        {:error, "unable to parse"}
    end
  end

  @jump_codes ["JGT", "JEQ", "JGE", "JLT", "JNE", "JLE", "JMP"]
  @dest_codes ["M", "D", "MD", "A", "AM", "AD", "AMD"]
  @comp_codes [
    "0",
    "1",
    "-1",
    "D",
    "A",
    "!D",
    "!A",
    "-D",
    "-A",
    "D+1",
    "A+1",
    "D-1",
    "A-1",
    "D+A",
    "D-A",
    "A-D",
    "D&A",
    "D|A"
  ]

  @spec parse_instruction(String.t()) :: {:ok, instruction} | {:error, String.t()}
  def parse_instruction(line) when is_binary(line) do
    case String.replace(line, " ", "") do
      l when byte_size(l) < 2 ->
        {:error, "Invalid instruction"}

      l ->
        do_parse_instruction(l)
    end
  end

  defp do_parse_instruction("@" <> addr) when byte_size(addr) >= 1 do
    if is_valid_symbol?(addr) do
      {:ok, {:a, addr}}
    else
      {:error, "symbol contain invalid character"}
    end
  end

  defp is_valid_symbol?(str), do: String.match?(str, ~r/^([A-Za-z]|[0-9]|_|\.|\$|:)+$/)

  defp do_parse_instruction("(" <> rest) when byte_size(rest) > 1 do
    case String.last(rest) do
      ")" ->
        label = String.slice(rest, 0..-2)

        if is_valid_symbol?(label) do
          {:ok, {:l, label}}
        else
          {:error, "l instruction contain invalid symbol character"}
        end

      _ ->
        {:error, "label instruction does not end with closing brace"}
    end
  end

  defp do_parse_instruction(x) do
    case String.split(x, ";") do
      # when there is ";" which means the second part must be jump instruction
      [dest_comp, jump] when jump in @jump_codes ->
        case parse_dest_comp(dest_comp) do
          {:ok, {dest, comp}} ->
            {:ok, {:c, %{comp: comp, dest: dest, jump: jump}}}

          err ->
            err
        end

      [_, _] ->
        {:error, "invalid jump expression"}

      [dest_comp] ->
        case parse_dest_comp(dest_comp) do
          {:ok, {nil, comp}} ->
            {:error, "invalid instruction with only comp"}

          {:ok, {dest, comp}} ->
            {:ok, {:c, %{comp: comp, dest: dest, jump: nil}}}

          err ->
            err
        end

      _ ->
        {:error, "more than 1 ';'"}
    end
  end

  defp parse_dest_comp(dest_comp) do
    case String.split(dest_comp, "=") do
      [dest, comp] when dest in @dest_codes ->
        case parse_comp(comp) do
          {:ok, comp} ->
            {:ok, {dest, comp}}

          err ->
            err
        end

      [comp] ->
        case parse_comp(comp) do
          {:ok, comp} ->
            {:ok, {nil, comp}}

          err ->
            err
        end

      _ ->
        {:error, "more than 1 '=' assignment"}
    end
  end

  defp parse_comp(comp) when comp in @comp_codes do
    {:ok, comp}
  end

  defp parse_comp(_comp), do: {:error, "invalid comp"}
end
