defmodule HackAssembler.AssemblyCode do
  alias HackAssembler.MachineCode

  @type instruction ::
          {:a, String.t()}
          | {:c, %{dest: String.t() | nil, comp: String.t(), jump: String.t() | nil}}
          | {:l, String.t()}

  @type t() :: list(instruction)

  @spec convert_to_machine_code(t()) :: MachineCode.t()
  def convert_to_machine_code(_), do: []
end

defmodule HackAssembler.MachineCode do
  @type t() :: list(instruction)
  @type instruction ::
          {:a, integer()}
          | {:c, %{dest: integer(), comp: integer(), jump: integer()}}
end
