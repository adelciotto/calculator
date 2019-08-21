module Calculator
  class EvaluatorError < StandardError
    def initialize(msg = "failed to evaluate expression")
      super
    end
  end

  class ParseNumberError < EvaluatorError
    def initialize(token)
      super("failed to parse number #{token}")
    end
  end

  class UnknownTokenError < EvaluatorError
    def initialize(token)
      super("failed to parse unkown token #{token}")
    end
  end
end
