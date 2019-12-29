defmodule HackAssembler do
  alias HackAssembler.{SymbolTable, Parser, Code}

  @spec assemble(String.t(), [{:output_path, String.t()}]) :: :ok | {:error, term()}
  def assemble(file_path, opts) do
    file_path
    |> File.read!()
    |> Parser.parse()
    |> case do
      {:ok, instructions} ->
        symbol_table =
          instructions
          |> SymbolTable.build()

        generated_file_path =
          case Keyword.get(opts, :output_path) do
            nil ->
              Path.rootname(file_path) <> ".hack"

            output_path ->
              output_path
          end

        encoded =
          instructions
          |> Code.encode(symbol_table)

        File.write(generated_file_path, encoded)

      err ->
        err
    end
  end
end
