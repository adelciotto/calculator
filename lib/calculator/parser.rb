require "calculator/errors/parser_error"

module Calculator
  class PostfixNode
    attr_reader :type, :value

    def initialize(type, value = "")
      @type = type
      @value = value
    end

    def ==(other)
      other.class == self.class && other.state == state
    end

    protected

    def state
      [@type, @value]
    end
  end

  class OperatorNode < PostfixNode
    attr_reader :precedance, :associativity

    def initialize(type, value)
      super(type, value)

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
    NULL_TOKEN = Token.new(:null, "", 0).freeze
    NULL_POSTFIX_NODE = PostfixNode.new(:null, "")

    def initialize(tokens = [], input = "")
      @tokens = tokens
      @input = input
      @current = 0
      @result = []
      @stack = []
      @errors = []
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
            # TODO: check if top of stack is func
            # TODO: append 'end_function' postfix node
            @stack << PostfixNode.new(:opening_paren)
          when :closing_paren
            @result << @stack.pop until peek_stack.type == :opening_paren
            @stack.pop if peek_stack.type == :opening_paren
          when :comma
            # TODO: check that the token is used inside function
            # TODO: check that peek_next is not end of function
            @result << @stack.pop until peek_stack.type == :opening_paren
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

      @result << @stack.pop until @stack.empty?
      @result
    end

    private

    def parse_number(token)
      number = str_to_number(token.literal)
      @result << PostfixNode.new(:number, number)
    rescue ArgumentError => e
      raise_error("failed to parse number '#{token.literal}': #{e.message}")
    end

    def parse_identifier(token)
      if peek_next_token.type == :opening_paren
        @stack << PostfixNode.new(:function, token.literal.to_sym)
      else
        @result << PostfixNode.new(:constant, token.literal.to_sym)
      end
    end

    def parse_operator(token)
      if unary_operator?(token)
        @stack << OperatorNode.new(:unary_operator, token.literal.to_sym)
      else
        operator = OperatorNode.new(:binary_operator, token.literal.to_sym)
        @result << @stack.pop while stack_has_greater_precedance?(operator)
        @stack << operator
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

    def str_to_number(str)
      Integer(str)
    rescue ArgumentError
      Float(str)
    end

    def peek_stack
      return NULL_POSTFIX_NODE if @stack.empty?
      @stack.last
    end

    def peek_next_token
      return NULL_TOKEN if @current >= @tokens.length - 1
      @tokens[@current + 1]
    end

    def peek_prev_token
      return NULL_TOKEN if @current.zero?
      @tokens[@current - 1]
    end

    def at_end?
      @current >= @tokens.length
    end

    def raise_error(msg, position = @current)
      raise Errors::ParserError.new(Errors.error_msg_with_input_annotation(msg, @input, position))
    end
  end
end
