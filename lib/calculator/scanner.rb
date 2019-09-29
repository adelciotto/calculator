require "calculator/errors/error"
require "calculator/errors/scanner_error"

module Calculator
  Token = Struct.new(:type, :literal, :position) {
    def self.new_null_token
      Token.new(:null, "", 0)
    end

    def to_s
      "{type: #{type}, literal: '#{literal}'}"
    end
  }

  class Scanner
    LETTER_PATTERN = /\A[a-zA-Z]\Z/.freeze
    NUMBER_PATTERN = /\A\d\Z/.freeze
    ALPHANUMERIC_PATTERN = /\A\w+\Z/.freeze
    WHITESPACE_PATTERN = /\A\s*\Z/.freeze
    CHAR_TOKENS = {
      "+" => :operator,
      "-" => :operator,
      "*" => :operator,
      "/" => :operator,
      "%" => :operator,
      "^" => :operator,
      "(" => :opening_paren,
      ")" => :closing_paren,
      "," => :comma,
    }.freeze

    def initialize(input = "")
      @input = input.strip
      @start = 0
      @current = 0
      @tokens = []
      @errors = []
    end

    def tokenize
      until at_end?
        @start = @current
        char = @input[@current]

        begin
          if letter?(char)
            tokenize_identifier
          elsif number?(char)
            tokenize_number
          elsif CHAR_TOKENS.include?(char)
            @current += 1
            add_token(CHAR_TOKENS[char])
          elsif whitespace?(char)
            @current += 1
            next
          else
            raise_error("illegal character '#{char}'")
          end
        rescue Errors::ScannerError => e
          @errors << e
          @current += 1
        end
      end

      raise Errors::ScannerError, @errors.join("\n") unless @errors.empty?
      @tokens << Token.new(:eof, "", @current)
      @tokens
    end

    private

    def tokenize_identifier
      advance_while { |char| alphanumeric?(char) }
      add_token(:identifier)
    end

    def tokenize_number
      advance_while { |char| number?(char) }

      if peek == "."
        raise_error("digit must come after decimal point", @current) unless number?(peek_next)

        @current += 1
        advance_while { |char| number?(char) }
      end

      if peek.downcase == "e"
        @current += 1
        @current += 1 if peek == "-" || peek == "+"

        raise_error("illegal character '#{peek}' in number", @current) unless number?(peek)
        advance_while { |char| number?(char) }
      end

      raise_error("illegal character '#{peek}' in number", @current) if letter?(peek)

      add_token(:number)
    end

    def add_token(type)
      literal = @input[@start..@current - 1]
      @tokens << Token.new(type, literal, @start)
    end

    def advance_while
      @current += 1 while !at_end? && yield(@input[@current])
    end

    def peek
      return "\0" if at_end?
      @input[@current]
    end

    def peek_next
      return "\0" if @current >= @input.length - 1
      @input[@current + 1]
    end

    def letter?(char)
      char.match(LETTER_PATTERN)
    end

    def number?(char)
      char.match(NUMBER_PATTERN)
    end

    def alphanumeric?(char)
      char.match(ALPHANUMERIC_PATTERN)
    end

    def whitespace?(char)
      char.match(WHITESPACE_PATTERN)
    end

    def at_end?
      @current >= @input.length
    end

    def raise_error(msg, position = @start)
      raise Errors::ScannerError.new(Errors.error_msg_with_input_annotation(msg, @input, position))
    end
  end
end
