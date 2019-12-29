defmodule HackAssembler do
  defmodule SymboleTable do
  end

  @spec assemble(String.t()) :: {:ok, String.t()} | {:error, term()}
  def assemble(file_path) do
    instructions =
      file_path
      |> File.read!()
      |> Parser.parse()

    symbol_table =
      instructions
      |> SymbolTable.build()

    Code.encode(instructions, symbol_table)
  end
end
