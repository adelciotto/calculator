# frozen_string_literal: true

module Calculator
  class Error < StandardError; end

  Function = Struct.new(:name, :num_args, :eval_func)
  Operator = Struct.new(:name, :eval_func, :precedance, :associativity)

  class Evaluator
    TOKENIZE_REGEXP_PATTERN = '(?<=[ops](?<!e[-+]))|(?=[ops](?<!e[-+]))'
                              .gsub('ops', '-+*/^%(),').freeze
    TOKENIZE_REGEXP = Regexp.new(TOKENIZE_REGEXP_PATTERN).freeze
    WHITESPACE_REGEXP = /\A\s*\Z/.freeze
    DIGIT_REGEXP = /\A\d+\z/.freeze

    def initialize
      @constants = { pi: Math::PI, e: Math::E, tau: Math::PI * 2 }.freeze

      # Ensure all the methods in the native ruby Math module
      # are available for the calculator.
      @functions = Math.methods(false)
                       .map { |method| Math.method(method) }
                       .each_with_object({}) do |method, result|
                         func = Function.new(method.name, method.arity, method.to_proc)
                         result[method.name] = func
                         result
                       end.freeze

      # Ensure all binary and unary operators are available for the calculator.
      @operators = {
        '+': Operator.new(:+, ->(x, y) { x + y }, 2, :left),
        '-': Operator.new(:-, ->(x, y) { x - y }, 2, :left),
        '*': Operator.new(:*, ->(x, y) { x * y }, 3, :left),
        '/': Operator.new(:/, ->(x, y) { x / y }, 3, :left),
        '%': Operator.new(:%, ->(x, y) { x % y }, 3, :left),
        '^': Operator.new(:^, ->(x, y) { Math.pow(x, y) }, 4, :right),
        '-_unary': Operator.new(:-, ->(x) { -x }, 4, :right)
      }.freeze
    end

    def eval(expression)
      parse(tokenize(expression))
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
        if @constants.include?(token.to_sym)
          output << token.to_sym
        elsif @functions.include?(token.to_sym) || token == '('
          stack << token
        elsif DIGIT_REGEXP.match(token)
          begin
            output << parse_number(token)
          rescue ArgumentError
            raise Error("failed to parse number #{token}")
          end
        elsif @operators.include?(token.to_sym)
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
          raise Error("unknown identifier #{token}")
        end
      end

      output << stack.pop until stack.empty?
      output
    end

    def greater_precedance?(token, stack_item)
      return false unless !stack_item.nil? && stack_item != '('

      stack_item_sym = stack_item.to_sym
      return true if @functions.include?(stack_item_sym)

      return false unless @operators.include?(stack_item_sym)

      current_op = @operators[token.to_sym]
      stack_item_op = @operators[stack_item_sym]
      (stack_item_op.precedance > current_op.precedance) ||
        (stack_item_op.precedance == current_op.precedance &&
         stack_item_op.associativity == :left)
    end

    def unary_operator?(tokens, token, index)
      return false unless token == '-'

      return true if index.zero?

      prev_token = tokens[index - 1]
      @operators.include?(prev_token.to_sym) || prev_token == '('
    end

    def parse_number(token)
      Integer(token)
    rescue ArgumentError
      Float(token)
    end

    def evaluate(postfix); end
  end
end
