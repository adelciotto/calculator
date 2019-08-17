# frozen_string_literal: true

require 'calculator/version'
require 'calculator/evaluator'

module Calculator
  def self.eval(expression)
    Evaluator.new.eval(expression)
  end
end
