require "calculator/version"
require "calculator/evaluator"
require "calculator/repl"

module Calculator
  def self.start_repl
    repl = Repl.new(Evaluator.new)
    repl.start
  end
end
