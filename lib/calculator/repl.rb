require "readline"
require "calculator/errors/error"
require "calculator/scanner"
require "calculator/parser"
require "calculator/evaluator"
require "calculator/version"

module Calculator
  WELCOME_MSG = <<~HEREDOC
    Welcome to calculator #{VERSION}! Type help to list commands.
    Type exit, CTRL-C or CTRL-D to quit the program. Built by adelciotto.
  HEREDOC
  HELP_MSG = <<~HEREDOC
    list_functions - Lists all the mathematical functions available (e.g sin, cos)
    list_constants - Lists all the mathematical constants available (e.g pi)
    list_operators - Lists all the binary and unary operators available (e.g +, -, *)
    exit - Quits the program
  HEREDOC
  HELP_COMMAND = "help"
  LIST_FUNCTIONS_COMMAND = "list_functions"
  LIST_CONSTANTS_COMMAND = "list_constants"
  LIST_OPERATORS_COMMAND = "list_operators"
  EXIT_COMMAND = "exit"

  class Repl
    def start
      # Store the state of the terminal.
      stty_save = `stty -g`.chomp

      puts(WELCOME_MSG)
      begin
        while (input = Readline.readline("> ", true))
          case input
          when HELP_COMMAND
            puts(HELP_MSG)
          when LIST_FUNCTIONS_COMMAND
            puts(Evaluator.list_functions)
          when LIST_CONSTANTS_COMMAND
            puts(Evaluator.list_constants)
          when LIST_OPERATORS_COMMAND
            puts(Evaluator.list_operators)
          when EXIT_COMMAND
            raise Interrupt
          else
            begin
              tokens = Scanner.new(input).tokenize
              postfix_nodes = Parser.new(tokens, input).parse
              result = Evaluator.new(postfix_nodes, input).eval
            rescue Errors::Error => e
              puts("ERROR: #{e}")
            else
              puts("=> #{result}")
            end
          end
        end
      rescue Interrupt
        system("stty", stty_save)
        exit
      end
    end
  end
end
