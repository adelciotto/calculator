# frozen_string_literal: true

require 'calculator/error'

module Calculator
  Function = Struct.new(:name, :num_args, :eval_func)
  Operator = Struct.new(:name, :eval_func, :precedance, :associativity, :unary) do
    def <(other)
      if associativity == :left
        precedance <= other.precedance
      else
        precedance < other.precedance
      end
    end
  end

  class Evaluator
    TOKENIZE_REGEXP_PATTERN = '(?<=[ops](?<!e[-+]))|(?=[ops](?<!e[-+]))'
                              .gsub('ops', '-+*/^%(),').freeze
    TOKENIZE_REGEXP = Regexp.new(TOKENIZE_REGEXP_PATTERN).freeze
    WHITESPACE_REGEXP = /\A\s*\Z/.freeze
    DIGIT_REGEXP = /\A\d+\z/.freeze

    def initialize
      @constants = { 'pi' => Math::PI, 'e' => Math::E, 'tau' => Math::PI * 2 }.freeze

      # Ensure all the methods in the native ruby Math module
      # are available for the calculator.
      @functions = Math.methods(false)
                       .map { |method| Math.method(method) }
                       .each_with_object({}) do |method, result|
                         # The evaluator doesn't support functions with a variable
                         # number of args. We will provide support for the variadic
                         # 'log' method by forcing the user to provide all the args.
                         arity = method.name == :log ? 2 : method.arity
                         next unless arity.positive?

                         func = Function.new(method.name, arity, method.to_proc)
                         result[method.name.to_s] = func
                         result
                       end.freeze

      # Ensure all binary and unary operators are available for the calculator.
      @operators = {
        '+' => Operator.new(:+, ->(x, y) { x + y }, 2, :left),
        '-' => Operator.new(:-, ->(x, y) { x - y }, 2, :left),
        '*' => Operator.new(:*, ->(x, y) { x * y }, 3, :left),
        '/' => Operator.new(:/, ->(x, y) { x.fdiv(y) }, 3, :left),
        '%' => Operator.new(:%, ->(x, y) { x % y }, 3, :left),
        '^' => Operator.new(:^, ->(x, y) { x**y }, 4, :right),
        '-_unary' => Operator.new(:-, ->(x) { -x }, 4, :right, true)
      }.freeze
    end

    def eval(expression)
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

      tokens.each_with_index do |token, i|
        if @constants.include?(token)
          output << token
        elsif @functions.include?(token) || token == '('
          stack << token
        elsif DIGIT_REGEXP.match(token[0])
          begin
            output << parse_number(token)
          rescue ArgumentError
            raise Error, "failed to parse number #{token}"
          end
        elsif @operators.include?(token)
          # Only unary operator supported at the moment is '-' for negative numbers.
          if unary_operator?(tokens, token, i)
            stack << '-_unary'
          else
            output << stack.pop while greater_precedance?(token, stack.last)
            stack << token
          end
        elsif token == ')'
          output << stack.pop while stack.last != '('
          stack.pop if stack.last == '('
        elsif token == ','
          output << stack.pop while stack.last != '('
        else
          raise Error, "unknown identifier #{token}"
        end
      end

      output << stack.pop until stack.empty?
      output
    end

    def parse_number(token)
      Integer(token)
    rescue ArgumentError
      Float(token)
    end

    def greater_precedance?(token, stack_item)
      return true if @functions.include?(stack_item)
      return false unless stack_item != '('
      return false unless @operators.include?(stack_item)

      @operators[token] < @operators[stack_item]
    end

    def unary_operator?(tokens, token, index)
      return false unless token == '-'
      return true if index.zero?

      prev_token = tokens[index - 1]
      @operators.include?(prev_token) || prev_token == '('
    end

    def evaluate(postfix)
      stack = []
      postfix.each do |item|
        if item.is_a?(Numeric)
          stack << item
        elsif @constants.include?(item)
          stack << @constants[item]
        elsif @operators.include?(item)
          op = @operators[item]
          if op.unary
            stack << op.eval_func.call(stack.pop)
          else
            lhs, rhs = stack.pop(2)
            stack << op.eval_func.call(lhs, rhs)
          end
        elsif @functions.include?(item)
          func = @functions[item]
          args = stack.pop(func.num_args)
          stack << func.eval_func.call(*args)
        end
      end

      return 0 if stack.empty?

      stack.pop
    end
  end
end
