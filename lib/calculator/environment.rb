module Calculator
  Operator = Struct.new(:name, :type, :eval_func) {
    def to_s
      "{name: #{name}, type: #{type}}"
    end
  }
  Function = Struct.new(:name, :num_args, :eval_func) {
    def to_s
      "{name: #{name}, num_args: #{num_args}}"
    end
  }

  class Environment
    attr_reader :constants, :binary_operators, :unary_operators, :functions

    def initialize
      @constants = {
        pi: Math::PI,
        tau: Math::PI * 2,
        e: Math::E,
      }.freeze
      @binary_operators = {
        "+": Operator.new(:+, :binary, ->(x, y) { x + y }),
        "-": Operator.new(:-, :binary, ->(x, y) { x - y }),
        "*": Operator.new(:*, :binary, ->(x, y) { x * y }),
        "/": Operator.new(:/, :binary, ->(x, y) { x.fdiv(y) }),
        "%": Operator.new(:%, :binary, ->(x, y) { x % y }),
        "^": Operator.new(:^, :binary, ->(x, y) { x**y }),
      }.freeze
      @unary_operators = {
        "-": Operator.new(:-, :unary, ->(x) { -x }),
      }.freeze
      @functions = math_functions
    end

    private

    def math_functions
      Math.methods(false)
        .map { |method| Math.method(method) }
        .each_with_object({}) { |method, result|
        # The evaluator doesn't support functions with a variable
        # number of args. We will provide support for the variadic
        # 'log' method by forcing the user to provide all the args.
        arity = method.name == :log ? 2 : method.arity
        next unless arity.positive?

        func = Function.new(method.name, arity, method.to_proc)
        result[method.name] = func
        result
      }.freeze
    end
  end
end
