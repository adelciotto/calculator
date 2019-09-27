module Calculator
  module Errors
    class ParserError < Error
      def initialize(msg)
        super(msg)
      end
    end
  end
end
