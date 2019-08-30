$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "calculator"

require "minitest/autorun"

require "minitest/reporters"
Minitest::Reporters.use!

Expectation = Struct.new(:input, :output, keyword_init: true)
