defmodule HackAssembler do
  alias HackAssembler.{Parser, AssemblyCode}

  @spec assemble(String.t(), [{:output_path, String.t()}]) :: :ok | {:error, term()}
  def assemble(file_path, opts) do
    with {:ok, assembly_codes} <- file_path |> File.read!() |> Parser.parse(),
         machine_codes <- assembly_codes |> AssemblyCode.convert_to_machine_code() do
      generated_file_path =
        case Keyword.get(opts, :output_path) do
          nil ->
            Path.rootname(file_path) <> ".hack"

          output_path ->
            output_path
        end

      File.write(generated_file_path, machine_codes)
    end
  end
end
