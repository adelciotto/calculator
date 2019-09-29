require "calculator/errors/parser_error"

module Calculator
  # TODO: simplify these classes into structs
  class PostfixNode
    attr_reader :type, :value, :position

    def self.new_null_node
      PostfixNode.new(:null, "", 0)
    end

    def initialize(type, value, position)
      @type = type
      @value = value
      @position = position
    end

    def ==(other)
      other.class == self.class && other.state == state
    end

    protected

    def state
      [@type, @value, @position]
    end
  end

  class OperatorNode < PostfixNode
    attr_reader :precedance, :associativity

    def initialize(type, value, position)
      super(type, value, position)

      case value
      when :-
        if type == :unary_operator
          @precedance = 4
          @associativity = :right
        else
          @precedance = 2
          @associativity = :left
        end
      when :+
        @precedance = 2
        @associativity = :left
      when :*
        @precedance = 3
        @associativity = :left
      when :/
        @precedance = 3
        @associativity = :left
      when :%
        @precedance = 3
        @associativity = :left
      when :^
        @precedance = 4
        @associativity = :right
      end
    end

    def >(other)
      if @associativity == :left
        @precedance >= other.precedance
      else
        @precedance > other.precedance
      end
    end

    protected

    def state
      [super, @precedance, @associativity].flatten
    end
  end

  class Parser
    def initialize(tokens = [], input = "")
      @tokens = tokens
      @input = input
      @current = 0
      @result = []
      @stack = []
      @in_function = false
      @errors = []

      unless @tokens.last && tokens.last.type == :eof
        raise Errors::ParserError.new("no EOF token")
      end
    end

    def parse
      until at_end?
        begin
          token = @tokens[@current]
          case token.type
          when :number
            parse_number(token)
          when :operator
            parse_operator(token)
          when :identifier
            parse_identifier(token)
          when :opening_paren
            @in_function = peek_stack.type == :function
            @stack << PostfixNode.new(:opening_paren, "", token.position)
            @result << PostfixNode.new(:end_function, "", 0) if @in_function
          when :closing_paren
            until peek_stack.type == :opening_paren || peek_stack.type == :null
              @result << @stack.pop
            end
            raise_error("unmatched paranthesis", token.position) if peek_stack.type == :null
            @stack.pop # discard remaining opening_paren from stack
          when :comma
            # TODO: check that the token is used inside function
            @result << @stack.pop until peek_stack.type == :opening_paren
            validate_next_token([:operator, :number, :identifier])
          when :eof
            break
          else
            raise_error("illegal token '#{token.literal}'")
          end
        rescue Errors::ParserError => e
          @errors << e
        ensure
          @current += 1
        end
      end

      raise Errors::ParserError, @errors.join("\n") unless @errors.empty?

      until @stack.empty?
        raise_error("unmatched paranthesis", peek_stack.position) if peek_stack.type == :opening_paren
        @result << @stack.pop
      end
      @result
    end

    private

    def parse_number(token)
      number = str_to_number(token.literal)
      @result << PostfixNode.new(:number, number, token.position)
      validate_next_token([:operator, :closing_paren, :comma, :eof])
    rescue ArgumentError => e
      raise_error("failed to parse number '#{token.literal}': #{e.message}")
    end

    def parse_identifier(token)
      if peek_next_token.type == :opening_paren
        @stack << PostfixNode.new(:function, token.literal.to_sym, token.position)
      else
        @result << PostfixNode.new(:constant, token.literal.to_sym, token.position)
        validate_next_token([:operator, :closing_paren, :comma, :eof])
      end
    end

    def parse_operator(token)
      if unary_operator?(token)
        @stack << OperatorNode.new(:unary_operator, token.literal.to_sym, token.position)
        validate_next_token([:number, :opening_paren, :identifier])
      else
        operator = OperatorNode.new(:binary_operator, token.literal.to_sym, token.position)
        @result << @stack.pop while stack_has_greater_precedance?(operator)
        @stack << operator
        validate_next_token([:number, :opening_paren, :identifier, :operator])
      end
    end

    def unary_operator?(token)
      return false unless token.literal == "-"
      return true if @current.zero?

      prev = peek_prev_token
      prev.type == :operator || prev.type == :opening_paren
    end

    def stack_has_greater_precedance?(operator)
      stack_top = peek_stack
      if stack_top.type == :function
        true
      elsif stack_top.is_a?(OperatorNode)
        stack_top > operator
      else
        false
      end
    end

    def validate_next_token(valid_types)
      next_token = peek_next_token
      unless valid_types.include?(next_token.type)
        raise_error("unexpected token #{next_token}", next_token.position)
      end
    end

    def str_to_number(str)
      Integer(str)
    rescue ArgumentError
      Float(str)
    end

    def peek_stack
      return PostfixNode.new_null_node if @stack.empty?
      @stack.last
    end

    def peek_next_token
      return Token.new_null_token if at_end?
      @tokens[@current + 1]
    end

    def peek_prev_token
      return Token.new_null_token if @current.zero?
      @tokens[@current - 1]
    end

    def at_end?
      @tokens[@current].type == :eof
    end

    def raise_error(msg, position = @current)
      raise Errors::ParserError.new(Errors.error_msg_with_input_annotation(msg, @input, position))
    end
  end
end
