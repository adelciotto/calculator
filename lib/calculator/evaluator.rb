require "calculator/errors/evaluator_error"
require "calculator/environment"

module Calculator
  class Evaluator
    @@environment = Environment.new

    def self.list_constants
      @@environment.constants.keys.join("\n")
    end

    def self.list_operators
      [@@environment.binary_operators.values, @@environment.unary_operators.values]
        .flatten
        .join("\n")
    end

    def self.list_functions
      @@environment.functions.values.join("\n")
    end

    def initialize(postfix_nodes = [], input = "")
      @postfix_nodes = postfix_nodes
      @input = input
      @stack = []
    end

    def eval
      @postfix_nodes.each do |node|
        eval_node(node)
      end

      return 0 if @stack.empty?
      @stack.pop
    end

    private

    def eval_node(node)
      case node.type
        when :number
          @stack << node.value
        when :constant
          value = @@environment.constants[node.value]
          raise_error("unknown constant #{node.value}", node.position) if value.nil?
          @stack << value
        when :end_function
          @stack << node.type
        when :unary_operator
          value = @stack.pop
          raise_error("invalid unary operand", node.position) unless value.is_a?(Numeric)
          operator = @@environment.unary_operators[node.value]
          raise_error("unknown unary operator #{node.value}", node.position) if operator.nil?
          @stack << operator.eval_func.call(value)
        when :binary_operator
          lhs, rhs = @stack.pop(2)
          raise_error("invalid operands provided to operator #{node.value}", node.position) unless lhs.is_a?(Numeric) && rhs.is_a?(Numeric)
          operator = @@environment.binary_operators[node.value]
          raise_error("unknown binary operator #{node.value}", node.position) if operator.nil?
          raise_error("division by zero", node.position) if rhs.zero?
          @stack << operator.eval_func.call(lhs, rhs)
        when :function
          function = @@environment.functions[node.value]
          args = pop_until { |value| value == :end_function }.reverse
          raise_error("no end of function", node.position) if @stack.last.nil?
          raise_error("unknown function #{node.value}", node.position) if function.nil?

          @stack.pop # discard remaining :end_function value from stack
          raise_error("incorrect number of args provided to function", node.position) unless args.length == function.num_args
          @stack << function.eval_func.call(*args)
        else
          raise_error("illegal postfix node '#{node}'", node.position)
      end
    end

    def pop_until(&block)
      result = []
      until @stack.empty? || yield(@stack.last)
        result << @stack.pop
      end
      result
    end

    def raise_error(msg, position)
      raise Errors::EvaluatorError.new(Errors.error_msg_with_input_annotation(msg, @input, position))
    end
  end
end
