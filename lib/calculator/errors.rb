module Calculator
  class Error < StandardError
    def initialize(msg = "failed to evaluate expression")
      super
    end
  end

  class ParseTokenError < Error
    def initialize(token)
      super("failed to parse token #{token}")
    end
  end

  class UnexpectedTokenError < Error
    def initialize(token)
      super("unexpected token #{token} in expression")
    end
  end

  class OperandError < Error
    def initialize(operator, num_args)
      super("incorrect number of operands for operator #{operator}, expected #{num_args}")
    end
  end

  class FunctionArgumentError < Error
    def initialize(function, num_args)
      super("incorrect number of arguments for function #{function}, expected #{num_args}")
    end
  end

  class DivideByZeroError < Error
    def initialize
      super("divided by zero")
    end
  end
end
