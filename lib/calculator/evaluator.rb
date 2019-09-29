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
      @errors = []
    end

    def eval
      @postfix_nodes.each_with_index do |node, i|
        eval_node(node, i)
      rescue Errors::EvaluatorError => e
        @errors << e
      ensure
        next
      end

      raise Errors::EvaluatorError, @errors.join("\n") unless @errors.empty?

      return 0 if @stack.empty?
      @stack.pop
    end

    private

    def eval_node(node, node_index)
      case node.type
        when :number
          @stack << node.value
        when :constant
          value = @@environment.constants[node.value]
          raise_error("unknown constant #{node.value}", node_index) if value.nil?
          @stack << value
        when :unary_operator
          value = @stack.pop
          operator = @@environment.unary_operators[node.value]
          raise_error("unknown unary operator #{node.value}", node_index) if operator.nil?
          @stack << operator.eval_func.call(value)
        when :binary_operator
          lhs, rhs = @stack.pop(2)
          operator = @@environment.binary_operators[node.value]
          raise_error("unknown binary operator #{node.value}", node_index) if operator.nil?
          @stack << operator.eval_func.call(lhs, rhs)
        when :function
          # TODO: read args until end_function is found
          pass
        else
          raise_error("illegal postfix node '#{node}'", node_index)
      end
    end

    def raise_error(msg, position)
      raise Errors::EvaluatorError.new(Errors.error_msg_with_input_annotation(msg, @input, position))
    end
  end
end
