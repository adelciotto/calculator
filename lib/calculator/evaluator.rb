require 'set'

module Calculator
  class Error < StandardError; end

  class Evaluator
    TOKENIZE_REGEXP_PATTERN = '(?<=[ops](?<!e[-+]))|(?=[ops](?<!e[-+]))'
                              .gsub('ops', '-+*/^%(),')
    TOKENIZE_REGEXP = Regexp.new(TOKENIZE_REGEXP_PATTERN)

    def eval(expression)
      tokenize(expression)
    end

    private

    def tokenize(expression)
      expression.split(TOKENIZE_REGEXP)
                .reject { |token| Set['', ' ', '\t'].include?(token) }
                .map(&:strip)
    end
  end
end
