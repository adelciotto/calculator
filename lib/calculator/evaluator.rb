require "calculator/errors"

module Calculator
  Function = Struct.new(:name, :num_args, :eval_func)
  Operator = Struct.new(:name, :eval_func, :precedance, :associativity, :unary) {
    def <(other)
      if associativity == :left
        precedance <= other.precedance
      else
        precedance < other.precedance
      end
    end
  }

  class Evaluator
    TOKENIZE_REGEXP_PATTERN = "(?<=[ops](?<![eE][-+]))|(?=[ops](?<![eE][-+]))"
      .gsub("ops", "-+*/^%(),").freeze
    TOKENIZE_REGEXP = Regexp.new(TOKENIZE_REGEXP_PATTERN).freeze
    WHITESPACE_REGEXP = /\A\s*\Z/.freeze
    DIGIT_REGEXP = /\A\d+\z/.freeze

    def initialize
      @constants = {"Pi" => Math::PI, "E" => Math::E, "Tau" => Math::PI * 2}.freeze

      # Ensure all the methods in the native ruby Math module
      # are available for the calculator.
      @functions = Math.methods(false)
        .map { |method| Math.method(method) }
        .each_with_object({}) { |method, result|
        # The evaluator doesn't support functions with a variable
        # number of args. We will provide support for the variadic
        # 'log' method by forcing the user to provide all the args.
        arity = method.name == :log ? 2 : method.arity
        next unless arity.positive?

        func = Function.new(method.name, arity, method.to_proc)
        result[method.name.to_s] = func
        result
      }.freeze

      # Ensure all binary and unary operators are available for the calculator.
      @operators = {
        "+" => Operator.new(:+, ->(x, y) { x + y }, 2, :left),
        "-" => Operator.new(:-, ->(x, y) { x - y }, 2, :left),
        "*" => Operator.new(:*, ->(x, y) { x * y }, 3, :left),
        "/" => Operator.new(:/, ->(x, y) { x.fdiv(y) }, 3, :left),
        "%" => Operator.new(:%, ->(x, y) { x % y }, 3, :left),
        "^" => Operator.new(:^, ->(x, y) { x**y }, 4, :right),
        "-_unary" => Operator.new(:-, ->(x) { -x }, 4, :right, true),
      }.freeze
    end

    def eval(expression)
      raise TypeError, "expected a String, got #{expression.class.name}" unless expression.is_a?(String)
      evaluate(parse(tokenize(expression)))
    end

    def supported_functions
      @functions.map { |_, func| "#{func.name}: Takes #{func.num_args} parameters" }
    end

    def supported_constants
      @constants.map { |name, _| name }
    end

    def supported_operators
      @operators.map do |_, op|
        if op.unary
          "#{op.name}: Unary operator"
        else
          "#{op.name}: Binary operator"
        end
      end
    end

    private

    def tokenize(expression)
      expression.split(TOKENIZE_REGEXP)
        .reject { |token| token =~ WHITESPACE_REGEXP }
        .map(&:strip)
    end

    def parse(tokens)
      output = []
      stack = []
      in_function = false

      tokens.each_with_index do |token, i|
        if @constants.include?(token)
          raise UnexpectedTokenError, token if prev_token(tokens, i) == ")"
          output << token
        elsif @functions.include?(token)
          stack << token
        elsif token == "("
          in_function = @functions.include?(tokens[i - 1])
          stack << token
          output << "end_function" if in_function
        elsif DIGIT_REGEXP.match(token[0])
          begin
            raise UnexpectedTokenError, token if prev_token(tokens, i) == ")"
            output << parse_number(token)
          rescue ArgumentError
            raise ParseTokenError, token
          end
        elsif @operators.include?(token)
          if unary_operator?(tokens, token, i)
            stack << "-_unary"
          else
            output << stack.pop while greater_precedance?(token, stack.last)
            stack << token
          end
        elsif token == ")"
          output << stack.pop while stack.last != "("
          stack.pop if stack.last == "("
        elsif token == ","
          raise UnexpectedTokenError, token unless in_function
          raise UnexpectedTokenError, token if tokens[i + 1] == ")"
          output << stack.pop while stack.last != "("
        else
          raise UnexpectedTokenError, token
        end
      end

      output << stack.pop until stack.empty?
      output
    end

    def prev_token(tokens, i)
      return unless i - 1 >= 0
      tokens[i - 1]
    end

    def parse_number(token)
      Integer(token)
    rescue ArgumentError
      Float(token)
    end

    def greater_precedance?(token, stack_item)
      return true if @functions.include?(stack_item)
      return false unless stack_item != "("
      return false unless @operators.include?(stack_item)

      @operators[token] < @operators[stack_item]
    end

    def unary_operator?(tokens, token, i)
      return false unless token == "-"
      return true if i.zero?

      prev = prev_token(tokens, i)
      @operators.include?(prev) || prev == "("
    end

    def evaluate(postfix)
      stack = []
      postfix.each do |item|
        if item.is_a?(Numeric) || item == "end_function"
          stack << item
        elsif @constants.include?(item)
          stack << @constants[item]
        elsif @operators.include?(item)
          op = @operators[item]
          if op.unary
            raise OperandError.new(op.name, 1) unless valid_operands?(stack, 1)
            stack << op.eval_func.call(stack.pop)
          else
            raise OperandError.new(op.name, 2) unless valid_operands?(stack, 2)
            lhs, rhs = stack.pop(2)
            raise DivideByZeroError if op.name == :/ && rhs.zero?
            stack << op.eval_func.call(lhs, rhs)
          end
        elsif @functions.include?(item)
          func = @functions[item]
          stack << func.eval_func.call(*function_args(stack, func))
        end
      end

      return 0 if stack.empty?
      stack.pop
    end

    def valid_operands?(stack, num_operands)
      operands = stack.last(num_operands)
      !operands.nil? && operands.length == num_operands && !operands.include?("end_function")
    end

    def function_args(stack, func)
      end_i = stack.rindex("end_function")
      raise FunctionArgumentError.new(func.name, func.num_args) if end_i.nil?

      args = stack.pop(stack.length - end_i)
      args.shift
      raise FunctionArgumentError.new(func.name, func.num_args) if args.nil? || args.length != func.num_args
      args
    end
  end
end
