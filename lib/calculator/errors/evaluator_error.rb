module Calculator
  module Errors
    class EvaluatorError < Error
      def initialize(msg)
        super(msg)
      end
    end
  end
end
