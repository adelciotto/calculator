require "calculator/version"
require "calculator/repl"

module Calculator
  def self.start_repl
    repl = Repl.new
    repl.start
  end
end
