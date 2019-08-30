require "test_helper"

describe "Calculator::Evaluator" do
  subject { Calculator::Evaluator.new }

  describe "#eval" do
    describe "when the input is not a String" do
      let(:expectations) do
        [
          Expectation.new(input: nil, output: "expected a String, got NilClass"),
          Expectation.new(input: 1, output: "expected a String, got Integer"),
          Expectation.new(input: 1.23, output: "expected a String, got Float"),
          Expectation.new(input: true, output: "expected a String, got TrueClass"),
          Expectation.new(input: false, output: "expected a String, got FalseClass"),
          Expectation.new(input: [], output: "expected a String, got Array"),
          Expectation.new(input: [1, 2], output: "expected a String, got Array"),
          Expectation.new(input: {}, output: "expected a String, got Hash"),
          Expectation.new(input: {a: 1, b: 2}, output: "expected a String, got Hash"),
        ]
      end

      it "raises a TypeError" do
        expectations.each do |expected|
          error = -> { subject.eval(expected.input) }.must_raise TypeError,
           "raises a TypeError with input #{expected.input}"
          error.message.must_equal expected.output, "error has correct error message with input #{expected.input}"
        end
      end
    end

    describe "when the input has no whitespace between tokens" do
      let(:expectations) do
        [
          Expectation.new(input: "1+2", output: 3),
          Expectation.new(input: "1+2-3*4/5%6^7", output: 0.6000000000000001),
          Expectation.new(input: "1*(2*3)", output: 6),
          Expectation.new(input: "1+atan2(2,3)", output: 1 + Math.atan2(2, 3)),
          Expectation.new(input: "1+atan2(Pi,Tau)", output: 1 + Math.atan2(Math::PI, Math::PI * 2)),
        ]
      end

      it "returns the correct result" do
        expectations.each do |expected|
          subject.eval(expected.input).must_equal expected.output,
            "returns correct result with input #{expected.input}"
        end
      end
    end

    describe "when the input has a mix of whitespace and no whitespace between tokens" do
      let(:expectations) do
        [
          Expectation.new(input: "1+ 2", output: 3),
          Expectation.new(input: "1+2 -3*4/ 5%6 ^ 7", output: 0.6000000000000001),
          Expectation.new(input: "1 *( 2* 3)", output: 6),
          Expectation.new(input: "1+atan2(2, 3)", output: 1 + Math.atan2(2, 3)),
          Expectation.new(input: "1+ atan2( Pi,Tau )", output: 1 + Math.atan2(Math::PI, Math::PI * 2)),
          Expectation.new(input: "atan2 ( Pi,Tau )", output: Math.atan2(Math::PI, Math::PI * 2)),
        ]
      end

      it "returns the correct result" do
        expectations.each do |expected|
          subject.eval(expected.input).must_equal expected.output,
            "returns correct result with input #{expected.input}"
        end
      end
    end

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
          Expectation.new(input: "1 1"),
          Expectation.new(input: "-1 1"),
          Expectation.new(input: "1abc"),
          Expectation.new(input: "-1abc"),
          Expectation.new(input: "1.2e"),
          Expectation.new(input: "1.2e*3"),
          Expectation.new(input: "1.2e3.4"),
          Expectation.new(input: "1.2e-3.4"),
          Expectation.new(input: "1.2e+3.4"),
        ]
      end

      it "raises a Calculator::ParseTokenError" do
        expectations.each do |expected|
          -> { subject.eval(expected.input) }.must_raise Calculator::ParseTokenError,
           "raises a Calculator::Error with input #{expected.input}"
        end
      end
    end

    describe "when the input is a valid constant" do
      let(:expectations) do
        [
          Expectation.new(input: "Pi", output: Math::PI),
          Expectation.new(input: "E", output: Math::E),
          Expectation.new(input: "Tau", output: Math::PI * 2),
        ]
      end

      it "returns the constant value" do
        expectations.each do |expected|
          subject.eval(expected.input).must_equal expected.output,
            "returns correct result with input #{expected.input}"
        end
      end
    end

    describe "when the input is a invalid constant" do
      let(:expectations) do
        [
          Expectation.new(input: "pi"),
          Expectation.new(input: "PI"),
          Expectation.new(input: "e"),
          Expectation.new(input: "tau"),
          Expectation.new(input: "TAU"),
          Expectation.new(input: "unknown"),
          Expectation.new(input: "e1"),
          Expectation.new(input: "-e1"),
          Expectation.new(input: "e-1"),
          Expectation.new(input: "e+1"),
          Expectation.new(input: "nil"),
        ]
      end

      it "raises a Calculator::UnexpectedTokenError" do
        expectations.each do |expected|
          -> { subject.eval(expected.input) }.must_raise Calculator::UnexpectedTokenError,
           "raises a Calculator::UnexpectedTokenError with input #{expected.input}"
        end
      end
    end

    describe "when the input is a valid function" do
      describe "with the correct number of arguments" do
        let(:expectations) do
          [
            Expectation.new(input: "atan(1)", output: Math.atan(1)),
            Expectation.new(input: "cosh(1)", output: Math.cosh(1)),
            Expectation.new(input: "sinh(1)", output: Math.sinh(1)),
            Expectation.new(input: "tanh(1)", output: Math.tanh(1)),
            Expectation.new(input: "acosh(1)", output: Math.acosh(1)),
            Expectation.new(input: "asinh(1)", output: Math.asinh(1)),
            Expectation.new(input: "atanh(1)", output: Math.atanh(1)),
            Expectation.new(input: "exp(1)", output: Math.exp(1)),
            Expectation.new(input: "log(1, 2)", output: Math.log(1, 2)),
            Expectation.new(input: "log2(1)", output: Math.log2(1)),
            Expectation.new(input: "log10(1)", output: Math.log10(1)),
            Expectation.new(input: "cbrt(1)", output: Math.cbrt(1)),
            Expectation.new(input: "frexp(1)", output: Math.frexp(1)),
            Expectation.new(input: "ldexp(1, 2)", output: Math.ldexp(1, 2)),
            Expectation.new(input: "hypot(1, 2)", output: Math.hypot(1, 2)),
            Expectation.new(input: "erf(1)", output: Math.erf(1)),
            Expectation.new(input: "erfc(1)", output: Math.erfc(1)),
            Expectation.new(input: "gamma(1)", output: Math.gamma(1)),
            Expectation.new(input: "lgamma(1)", output: Math.lgamma(1)),
            Expectation.new(input: "sqrt(1)", output: Math.sqrt(1)),
            Expectation.new(input: "atan2(1, 2)", output: Math.atan2(1, 2)),
            Expectation.new(input: "cos(1)", output: Math.cos(1)),
            Expectation.new(input: "sin(1)", output: Math.sin(1)),
            Expectation.new(input: "tan(1)", output: Math.tan(1)),
            Expectation.new(input: "acos(1)", output: Math.acos(1)),
            Expectation.new(input: "asin(1)", output: Math.asin(1)),
          ]
        end

        it "returns the correct value" do
          expectations.each do |expected|
            subject.eval(expected.input).must_equal expected.output,
              "returns correct result with input #{expected.input}"
          end
        end
      end

      describe "with the too many arguments" do
        let(:expectations) do
          [
            Expectation.new(input: "atan(1, 2)"),
            Expectation.new(input: "cosh(1, 2)"),
            Expectation.new(input: "sinh(1, 2)"),
            Expectation.new(input: "tanh(1, 2)"),
            Expectation.new(input: "acosh(1, 2)"),
            Expectation.new(input: "asinh(1, 2)"),
            Expectation.new(input: "atanh(1, 2)"),
            Expectation.new(input: "exp(1, 2)"),
            Expectation.new(input: "log(1, 2, 3)"),
            Expectation.new(input: "log2(1, 2)"),
            Expectation.new(input: "log10(1, 2)"),
            Expectation.new(input: "cbrt(1, 2)"),
            Expectation.new(input: "frexp(1, 2)"),
            Expectation.new(input: "ldexp(1, 2, 3)"),
            Expectation.new(input: "hypot(1, 2, 3)"),
            Expectation.new(input: "erf(1, 2)"),
            Expectation.new(input: "erfc(1, 2)"),
            Expectation.new(input: "gamma(1, 2)"),
            Expectation.new(input: "lgamma(1, 2)"),
            Expectation.new(input: "sqrt(1, 2)"),
            Expectation.new(input: "atan2(1, 2, 2)"),
            Expectation.new(input: "cos(1, 2)"),
            Expectation.new(input: "sin(1, 2)"),
            Expectation.new(input: "tan(1, 2)"),
            Expectation.new(input: "acos(1, 2)"),
            Expectation.new(input: "asin(1, 2)"),
            Expectation.new(input: "atan(1, 2, 3, 4, 5, 6)"),
          ]
        end

        it "raises a Calculator::FunctionArgumentError" do
          expectations.each do |expected|
            -> { subject.eval(expected.input) }.must_raise Calculator::FunctionArgumentError,
             "raises a Calculator::FunctionArgumentError with input #{expected.input}"
          end
        end
      end

      describe "with the too few arguments" do
        let(:expectations) do
          [
            Expectation.new(input: "atan()"),
            Expectation.new(input: "cosh()"),
            Expectation.new(input: "sinh()"),
            Expectation.new(input: "tanh()"),
            Expectation.new(input: "acosh()"),
            Expectation.new(input: "asinh()"),
            Expectation.new(input: "atanh()"),
            Expectation.new(input: "exp()"),
            Expectation.new(input: "log(1)"),
            Expectation.new(input: "log()"),
            Expectation.new(input: "log2()"),
            Expectation.new(input: "log10()"),
            Expectation.new(input: "cbrt()"),
            Expectation.new(input: "frexp()"),
            Expectation.new(input: "ldexp(1)"),
            Expectation.new(input: "ldexp()"),
            Expectation.new(input: "hypot(1)"),
            Expectation.new(input: "hypot()"),
            Expectation.new(input: "erf()"),
            Expectation.new(input: "erfc()"),
            Expectation.new(input: "gamma()"),
            Expectation.new(input: "lgamma()"),
            Expectation.new(input: "sqrt()"),
            Expectation.new(input: "atan2(1)"),
            Expectation.new(input: "atan2()"),
            Expectation.new(input: "cos()"),
            Expectation.new(input: "sin()"),
            Expectation.new(input: "tan()"),
            Expectation.new(input: "acos()"),
            Expectation.new(input: "asin()"),
            Expectation.new(input: "atan"),
          ]
        end

        it "raises a Calculator::FunctionArgumentError" do
          expectations.each do |expected|
            -> { subject.eval(expected.input) }.must_raise Calculator::FunctionArgumentError,
             "raises a Calculator::FunctionArgumentError with input #{expected.input}"
          end
        end
      end
    end

    describe "when the input is a invalid function" do
      let(:expectations) do
        [
          Expectation.new(input: "foo(1)"),
          Expectation.new(input: "bar(Pi)"),
          Expectation.new(input: "unknown(1, 2)"),
          Expectation.new(input: "sinn(1)"),
          Expectation.new(input: "coss(2)"),
          Expectation.new(input: "sin(3, )"),
          Expectation.new(input: "cos(,)"),
        ]
      end

      it "raises a Calculator::UnexpectedTokenError" do
        expectations.each do |expected|
          -> { subject.eval(expected.input) }.must_raise Calculator::UnexpectedTokenError,
           "raises a Calculator::UnexpectedTokenError with input #{expected.input}"
        end
      end
    end

    describe "when the input is a valid binary operator" do
      describe "with two operands" do
        let(:expectations) do
          [
            Expectation.new(input: "1 + 2", output: 3),
            Expectation.new(input: "1 - 2", output: -1),
            Expectation.new(input: "1 * 2", output: 2),
            Expectation.new(input: "1 / 2", output: 0.5),
            Expectation.new(input: "1 % 2", output: 1),
            Expectation.new(input: "2 ^ 2", output: 4),
          ]
        end

        it "returns the correct value" do
          expectations.each do |expected|
            subject.eval(expected.input).must_equal expected.output,
              "returns correct result with input #{expected.input}"
          end
        end
      end

      describe "with one operand" do
        let(:expectations) do
          [
            Expectation.new(input: "1 +"),
            Expectation.new(input: "+ 1"),
            Expectation.new(input: "1 -"),
            Expectation.new(input: "1 *"),
            Expectation.new(input: "* 1"),
            Expectation.new(input: "1 /"),
            Expectation.new(input: "/ 1"),
            Expectation.new(input: "1 %"),
            Expectation.new(input: "% 1"),
            Expectation.new(input: "2 ^"),
            Expectation.new(input: "^ 2"),
          ]
        end

        it "raises a Calculator::OperandError" do
          expectations.each do |expected|
            -> { subject.eval(expected.input) }.must_raise Calculator::OperandError,
             "raises a Calculator::OperandError with input #{expected.input}"
          end
        end
      end

      describe "with no operands" do
        let(:expectations) do
          [
            Expectation.new(input: "+"),
            Expectation.new(input: "*"),
            Expectation.new(input: "/"),
            Expectation.new(input: "%"),
            Expectation.new(input: "^"),
          ]
        end

        it "raises a Calculator::OperandError" do
          expectations.each do |expected|
            -> { subject.eval(expected.input) }.must_raise Calculator::OperandError,
             "raises a Calculator::OperandError with input #{expected.input}"
          end
        end
      end

      describe "when dividing by zero" do
        it "raises a Calculator::DivideByZeroError" do
          -> { subject.eval("1 / 0") }.must_raise Calculator::DivideByZeroError,
           "raises a Calculator::DivideByZeroError"
        end
      end
    end

    describe "when the input is a unary operator" do
      describe "with one operand" do
        it "returns the correct result" do
          subject.eval("-1").must_equal(-1)
        end
      end

      describe "with no operand" do
        it "raises a Calculator::OperandError" do
          -> { subject.eval("-") }.must_raise Calculator::OperandError
        end
      end
    end

    describe "when the input is a invalid binary operator" do
      let(:expectations) do
        [
          Expectation.new(input: "1 ! 2"),
          Expectation.new(input: "!1"),
          Expectation.new(input: "1 @ 2"),
          Expectation.new(input: "1 # 2"),
          Expectation.new(input: "1 $ 2"),
          Expectation.new(input: "$1"),
          Expectation.new(input: "1 & 2"),
          Expectation.new(input: "1 = 2"),
          Expectation.new(input: "1 == 2"),
          Expectation.new(input: "1 != 2"),
          Expectation.new(input: "1 \ 2"),
        ]
      end

      it "raises a Calculator::Error" do
        expectations.each do |expected|
          -> { subject.eval(expected.input) }.must_raise Calculator::Error,
           "raises a Calculator::Error with input #{expected.input}"
        end
      end
    end

    describe "when the input is an expression within paranthesis" do
      describe "when the paranthesis are matched" do
        it "returns the correct result" do
        end
      end

      describe "when the paranthesis are unmatched" do
        it "raises a Calculator::UnamatchedParanthesis" do
        end
      end
    end

    describe "when the input contains a trailing comma" do
    end

    describe "when the input contains an unexpected number" do
    end

    describe "when the input contains composite functions" do
      let(:expectations) do
        [
          Expectation.new(
            input: "atan2(sin(1), tan(2))",
            output: Math.atan2(Math.sin(1), Math.tan(2))
          ),
          Expectation.new(
            input: "atan2(sin(1) + cos(2), tan(Pi) - sin(Tau))",
            output: Math.atan2(Math.sin(1) + Math.cos(2), Math.tan(Math::PI) - Math.sin(Math::PI * 2))
          ),
          Expectation.new(
            input: "atan2(sin(cos(tan(1))), tan(2))",
            output: Math.atan2(Math.sin(Math.cos(Math.tan(1))), Math.tan(2))
          ),
          Expectation.new(
            input: "atan2(sin(1 + 2 - cos(3)), 4 * tan(5 / 6 ^ 7))",
            output: Math.atan2(Math.sin(1 + 2 - Math.cos(3)), 4 * Math.tan(5.fdiv(6**7)))
          ),
        ]
      end

      it "returns the correct result" do
        expectations.each do |expect|
          subject.eval(expect.input).must_equal expect.output
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
