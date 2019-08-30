module Calculator
  module Errors
    class Error < RuntimeError
      def initialize(msg = "failed to evaluate input")
        super
      end
    end

    def self.error_msg_with_input_annotation(msg, input, current_position)
      "#{msg}:\n#{input}\n#{"^".rjust(current_position + 1)}"
    end
  end
end
