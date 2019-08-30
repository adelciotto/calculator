module Calculator
  module Errors
    class ScannerError < Error
      def initialize(msg)
        super(msg)
      end
    end
  end
end
