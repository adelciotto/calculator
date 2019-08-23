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
end
