require "calculator/version"
require "calculator/evaluator"
require "calculator/repl"
require "calculator/scanner"

module Calculator
  def self.start_repl
    repl = Repl.new(Evaluator.new)
    repl.start
  end
end
