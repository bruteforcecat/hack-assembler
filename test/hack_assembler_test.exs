defmodule HackAssemblerTest do
  use ExUnit.Case
  doctest HackAssembler

  @fixtures [
    %{
      assembly_code_file_path: "./test/fixtures/add/Add.asm",
      machine_code_file_path: "./test/fixtures/add/Add.hack"
    },
    %{
      assembly_code_file_path: "./test/fixtures/max/Max.asm",
      machine_code_file_path: "./test/fixtures/max/Max.hack"
    },
    %{
      assembly_code_file_path: "./test/fixtures/max/MaxL.asm",
      machine_code_file_path: "./test/fixtures/max/MaxL.hack"
    },
    %{
      assembly_code_file_path: "./test/fixtures/pong/Pong.asm",
      machine_code_file_path: "./test/fixtures/pong/Pong.hack"
    },
    %{
      assembly_code_file_path: "./test/fixtures/pong/PongL.asm",
      machine_code_file_path: "./test/fixtures/pong/PongL.hack"
    },
    %{
      assembly_code_file_path: "./test/fixtures/rect/Rect.asm",
      machine_code_file_path: "./test/fixtures/rect/Rect.hack"
    },
    %{
      assembly_code_file_path: "./test/fixtures/rect/RectL.asm",
      machine_code_file_path: "./test/fixtures/rect/RectL.hack"
    }
  ]

  describe "assemble/1" do
    setup do
      File.mkdir_p!(tmp_path())
      on_exit(fn -> File.rm_rf(tmp_path()) end)
      :ok
    end

    test "successfully compile hack assembly code to hack machine code" do
      for %{
            assembly_code_file_path: assembly_code_file_path,
            machine_code_file_path: machine_code_file_path
          } <- @fixtures do
        output_path = tmp_path(Path.basename(assembly_code_file_path))
        assert :ok == HackAssembler.assemble(assembly_code_file_path, output_path: output_path)
        IO.inspect(assembly_code_file_path)
        assert File.read!(machine_code_file_path) == File.read!(output_path)
      end
    end
  end

  defp tmp_path() do
    Path.expand("../../tmp", __DIR__)
  end

  defp tmp_path(extra) do
    Path.join(tmp_path(), extra)
  end
end
