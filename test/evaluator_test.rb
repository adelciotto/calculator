# frozen_string_literal: true

require "test_helper"

describe "Calculator::Evaluator" do
  subject { evaluator }

  let(:evaluator) { Calculator::Evaluator.new }

  describe "#eval" do
    describe "when the input is a valid number" do
      let(:expectations) do
        [
          Expectation.new(input: "1", output: 1),
          Expectation.new(input: "-1", output: -1),
          Expectation.new(input: "--1", output: 1),
          Expectation.new(input: "---1", output: -1),
          Expectation.new(input: "123456", output: 123456),
          Expectation.new(input: "-123456", output: -123456),
          Expectation.new(input: "1.23", output: 1.23),
          Expectation.new(input: "-1.23", output: -1.23),
          Expectation.new(input: "1.2e3", output: 1200.0),
          Expectation.new(input: "1.2e+3", output: 1200.0),
          Expectation.new(input: "1.2e-3", output: 0.0012),
          Expectation.new(input: "1.2E3", output: 1200.0),
          Expectation.new(input: "1.2E-3", output: 0.0012),
          Expectation.new(input: "1.2E+3", output: 1200.0),
          Expectation.new(input: (1 << 64).to_s, output: 18446744073709551616),
          Expectation.new(input: (-1 << 64).to_s, output: -18446744073709551616),
          Expectation.new(input: Float::MAX.to_s, output: 1.7976931348623157e+308),
          Expectation.new(input: (-Float::MAX).to_s, output: -1.7976931348623157e+308),
        ]
      end

      it "returns the number" do
        expectations.each do |expected|
          subject.eval(expected.input).must_equal expected.output,
            "returns correct result with input #{expected.input}"
        end
      end
    end

    describe "when the input is a invalid number" do
      let(:expectations) do
        [
          Expectation.new(input: "1 1", output: "failed to parse number 1 1"),
          Expectation.new(input: "-1 1", output: "failed to parse number 1 1"),
          Expectation.new(input: "1abc", output: "failed to parse number 1abc"),
          Expectation.new(input: "-1abc", output: "failed to parse number 1abc"),
          Expectation.new(input: "e1", output: "unknown identifier e1"),
          Expectation.new(input: "-e1", output: "unknown identifier e1"),
          Expectation.new(input: "e-1", output: "unknown identifier e-1"),
          Expectation.new(input: "e+1", output: "unknown identifier e+1"),
          Expectation.new(input: "1.2e", output: "failed to parse number 1.2e"),
          Expectation.new(input: "1.2e*3", output: "failed to parse number 1.2e"),
          Expectation.new(input: "1.2e3.4", output: "failed to parse number 1.2e3.4"),
          Expectation.new(input: "1.2e-3.4", output: "failed to parse number 1.2e-3.4"),
          Expectation.new(input: "1.2e+3.4", output: "failed to parse number 1.2e+3.4"),
        ]
      end

      it "raises a Calculator::Error" do
        expectations.each do |expected|
          err = -> { subject.eval(expected.input) }.must_raise Calculator::Error,
           "raises Calculator::Error with input #{expected.input}"
          err.message.must_match expected.output, "raises correct error msg with input #{expected.input}"
        end
      end
    end
  end

  describe "#supported_functions" do
    let(:expected_functions) do
      [
        "atan: Takes 1 parameters",
        "cosh: Takes 1 parameters",
        "sinh: Takes 1 parameters",
        "tanh: Takes 1 parameters",
        "acosh: Takes 1 parameters",
        "asinh: Takes 1 parameters",
        "atanh: Takes 1 parameters",
        "exp: Takes 1 parameters",
        "log: Takes 2 parameters",
        "log2: Takes 1 parameters",
        "log10: Takes 1 parameters",
        "cbrt: Takes 1 parameters",
        "frexp: Takes 1 parameters",
        "ldexp: Takes 2 parameters",
        "hypot: Takes 2 parameters",
        "erf: Takes 1 parameters",
        "erfc: Takes 1 parameters",
        "gamma: Takes 1 parameters",
        "lgamma: Takes 1 parameters",
        "sqrt: Takes 1 parameters",
        "atan2: Takes 2 parameters",
        "cos: Takes 1 parameters",
        "sin: Takes 1 parameters",
        "tan: Takes 1 parameters",
        "acos: Takes 1 parameters",
        "asin: Takes 1 parameters",
      ]
    end

    it "returns the supported functions" do
      subject.supported_functions.must_equal expected_functions
    end
  end

  describe "#supported_constants" do
    let(:expected_constants) { %w[Pi E Tau] }

    it "returns the supported constants" do
      subject.supported_constants.must_equal expected_constants
    end
  end

  describe "#supported_operators" do
    let(:expected_operators) do
      [
        "+: Binary operator",
        "-: Binary operator",
        "*: Binary operator",
        "/: Binary operator",
        "%: Binary operator",
        "^: Binary operator",
        "-: Unary operator",
      ]
    end

    it "returns the supported operators" do
      subject.supported_operators.must_equal expected_operators
    end
  end
end
