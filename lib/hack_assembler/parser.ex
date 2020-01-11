defmodule HackAssembler.Parser do

  @jump_codes ["JGT", "JEQ", "JGE", "JLT", "JNE", "JLE", "JMP"]
  @dest_codes ["MD", "AM", "AD", "AMD", "M", "D", "A"]
  @comp_codes [
    "M+1",
    "M-1",
    "D+M",
    "D-M",
    "M-D",
    "D&M",
    "D|M",
    "D+1",
    "A+1",
    "D-1",
    "A-1",
    "D+A",
    "D-A",
    "A-D",
    "D&A",
    "D|A",
    "0",
    "1",
    "-1",
    "D",
    "A",
    "!D",
    "!A",
    "-D",
    "-A",
    "M",
    "!M",
    "-M"
  ]

  alias HackAssembler.AssemblyCode

  @spec parse(String.t()) :: {:ok, list(AssemblyCode.instruction())} | {:error, String.t()}
  def parse(machine_code_str) do
    parser = many(parse_instruction())

    case parser.(machine_code_str) do
      {:ok, instructions, ""} ->
        {:ok, instructions}

      err ->
        err
    end
  end

  def parse_instruction() do
    sequence([
      whitespace(),
      many(parse_comment()),
      choice([
        parser_c_instruction(),
        parser_a_instruction(),
        parser_l_instruction()
      ]),
      skip_until_next_non_blank_line()
    ])
    |> map(fn [_, _, instruction, _] ->
      IO.inspect instruction, label: "instruction"
      instruction
    end)
  end

#  def parse_instruction() do
#    sequence([
#      whitespace(),
#      many(parse_comment()),
#      choice([
#        parser_c_instruction(),
#        parser_a_instruction(),
#        parser_l_instruction()
#      ]),
#      skip_until_next_non_blank_line()
#    ])
#    |> map(fn [_, _, instruction, _] ->
#      IO.inspect instruction, label: "instruction"
#      instruction
#    end)
#  end

  def parse_comment() do
    sequence([
      whitespace(),
      sequence([ char(?/), char(?/) ]),
      skip_until_next_non_blank_line(),
    ])
    |> map(fn _ ->
      nil
    end)
  end

  def parser_c_instruction() do
    sequence([
      parse_dest(),
      parse_comp(),
      parse_jump()
    ])
    |> bind(fn
      [nil, _comp, nil] ->
        {:error, "both dest and jump are empty"}

      [dest, comp, jump] ->
        dest =
          case dest do
            nil ->
              nil

            [dest, _] ->
              dest
          end

        jump =
          case jump do
            nil ->
              nil

            [_, jump] ->
              jump
          end

        {:ok, {:c, %{dest: dest, comp: comp, jump: jump}}}
    end)
  end

  def parser_a_instruction() do
    sequence([
      char(?@),
      choice([
        some(digit()),
        identifier()
      ])
    ])
    |> map(fn [_, addr] ->
      {:a, to_string(addr)}
    end)
  end

  def parser_l_instruction() do
    sequence([
      char(?(),
      identifier(),
      char(?))
    ])
    |> map(fn [_, label, _] ->
      {:l, label}
    end)
  end

  def parse_dest() do
    choice([
      sequence([
        choice(Enum.map(@dest_codes, &keyword/1)),
        char(?=)
      ]),
      return(nil)
    ])
  end

  def parse_jump() do
    choice([
      sequence([
        char(?;),
        choice(Enum.map(@jump_codes, &keyword/1))
      ]),
      return(nil)
    ])
  end

  def parse_comp() do
    @comp_codes
    |> Enum.map(&keyword/1)
    |> choice()
  end

  def choice(parsers) when is_list(parsers) do
    fn input ->
      case parsers do
        [] ->
          {:error, "no parser suceeded"}

        [first_parser | other_parsers] ->
          with {:error, _reason} <- first_parser.(input),
               do: choice(other_parsers).(input)
      end
    end
  end

  def sequence(parsers) do
    fn input ->
      case parsers do
        [] ->
          {:ok, [], input}

        [first_parser | other_parsers] ->
          with {:ok, first_term, rest} <- first_parser.(input),
               {:ok, other_terms, rest} <- sequence(other_parsers).(rest),
               do: {:ok, [first_term | other_terms], rest}
      end
    end
  end

  def return(val) do
    fn input ->
      {:ok, val, input}
    end
  end

  def keyword(expected) do
    identifier()
    |> token()
    |> satisfy(fn identifier ->
      identifier == expected
    end)
    |> map(fn _ -> expected end)
  end

  def identifier() do
    many(identifier_char())
    |> satisfy(&(&1 != []))
    |> map(&to_string/1)
  end

  def some(parser) do
    fn input ->
      case many(parser).(input) do
        {:ok, [], _} ->
          {:error, "none is match"}

        ok ->
          ok
      end
    end
  end

  def many(parser) do
    fn input ->
      case parser.(input) do
        {:error, _reason} ->
          {:ok, [], input}

        {:ok, first_term, rest} ->
          {:ok, other_terms, rest} = many(parser).(rest)
          {:ok, [first_term | other_terms], rest}
      end
    end
  end

  def map(parser, mapper) do
    fn input ->
      with {:ok, term, rest} <- parser.(input),
           do: {:ok, mapper.(term), rest}
    end
  end

  def bind(parser, g) do
    fn input ->
      with {:ok, term, rest} <- parser.(input) do
        case g.(term) do
          {:ok, result} ->
            {:ok, result, rest}

          {:error, e} ->
            {:error, e}
        end
      end
    end
  end

  def skip(parser) do
    fn input ->
      with {:ok, _term, rest} <- parser.(input),
           do: {:ok, nil, rest}
    end
  end

  def identifier_char(),
    do:
      choice([ascii_letter(), char(?_), char(?:), char(?_), char(?|), char(?+), char(?-), digit()])

  def satisfy(parser, acceptor) do
    fn input ->
      with {:ok, term, rest} <- parser.(input) do
        if acceptor.(term),
          do: {:ok, term, rest},
          else: {:error, "term rejected"}
      end
    end
  end

  def token(parser) do
    sequence([
      many(choice([char(?\s), char(?\n)])),
      parser,
      many(choice([char(?\s), char(?\n)]))
    ])
    |> map(fn [_lw, term, _tw] -> term end)
  end

  def none_of(chars), do: satisfy(char(), fn char -> char not in chars end)

  def digit(), do: satisfy(char(), fn char -> char in ?0..?9 end)

  def ascii_letter(), do: satisfy(char(), fn char -> char in ?A..?Z or char in ?a..?z end)

  def whitespace(), do: many(choice([char(?\s), char(?\r), char(?\n), keyword("\r\n")]))

  def end_of_line() do
    choice([sequence([char(?\r), char(?\n)]), char(?\n), char(?\r)])
  end

  def skip_until_next_non_blank_line() do
    sequence(
      [
        many(none_of([?\r, ?\n])),
        many(end_of_line())
      ]
    )
  end


  def char(expected), do: satisfy(char(), &(&1 == expected))

  def char() do
    fn input ->
      case input do
        "" ->
          {:error, "unexpected end of input"}

        <<char::utf8, rest::binary>> ->
          {:ok, char, rest}
      end
    end
  end
end
