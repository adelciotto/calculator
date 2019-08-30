require "test_helper"

class TestScanner < Minitest::Test
  def test_with_no_input
    assert_equal [], Calculator::Scanner.new.tokenize
  end

  def test_with_valid_int
    inputs = [
      "0",
      "1",
      "12",
      "123456",
      (1 << 64).to_s,
      "9999999999",
    ]

    inputs.each do |input|
      expected_tokens = [Calculator::Token.new(:number, input, 0)]
      assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
    end
  end

  def test_with_invalid_int
    inputs = [
      "0a",
      "123abc",
    ]

    inputs.each do |input|
      assert_raises Calculator::Errors::ScannerError do
        Calculator::Scanner.new(input).tokenize
      end
    end
  end

  def test_with_valid_decimal
    inputs = [
      "0.0",
      "1.23",
      "12.3456",
      "123456.789",
      "999999999999.9999999999",
    ]

    inputs.each do |input|
      expected_tokens = [Calculator::Token.new(:number, input, 0)]
      assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
    end
  end

  def test_with_invalid_decimal
    inputs = [
      ".0",
      "1.",
      "1.2.3",
      "123.456.7",
      "1.-2",
      "1.+2",
    ]

    inputs.each do |input|
      assert_raises Calculator::Errors::ScannerError do
        Calculator::Scanner.new(input).tokenize
      end
    end
  end

  def test_with_valid_scientific_notation
    inputs = [
      "0E1",
      "0e+1",
      "0e-1",
      "0E-1",
      "0E-1",
      "1.245e67",
      "1.245E67",
      "1.245e+67",
      "1.245e-67",
      "1.245E+67",
      "1.245E-67",
      Float::MAX.to_s,
    ]

    inputs.each do |input|
      expected_tokens = [Calculator::Token.new(:number, input, 0)]
      assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
    end
  end

  def test_with_invalid_scientific_notation
    inputs = [
      "0e",
      "0E",
      "1e--2",
      "1e*2",
      "1e/2",
      "1e^2",
      "1e%2",
      "1e2.3",
      "1e2.3.4",
    ]

    inputs.each do |input|
      assert_raises Calculator::Errors::ScannerError do
        Calculator::Scanner.new(input).tokenize
      end
    end
  end

  def test_with_valid_operator
    inputs = [
      "+",
      "-",
      "*",
      "/",
      "%",
      "^",
    ]

    inputs.each do |input|
      expected_tokens = [Calculator::Token.new(:operator, input, 0)]
      assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
    end
  end

  def test_with_invalid_operator
    inputs = [
      "&",
      "$",
      "#",
      "@",
    ]

    inputs.each do |input|
      assert_raises Calculator::Errors::ScannerError do
        Calculator::Scanner.new(input).tokenize
      end
    end
  end

  def test_with_identifier
    inputs = [
      "pi",
      "tau",
      "e",
    ]

    inputs.each do |input|
      expected_tokens = [Calculator::Token.new(:identifier, input, 0)]
      assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
    end
  end

  def test_with_function_call_one_arg_int
    input = "sin(1)"
    expected_tokens = [
      Calculator::Token.new(:identifier, "sin", 0),
      Calculator::Token.new(:opening_paren, "(", 3),
      Calculator::Token.new(:number, "1", 4),
      Calculator::Token.new(:closing_paren, ")", 5),
    ]

    assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
  end

  def test_with_function_call_one_arg_decimal
    input = "sin(1.23)"
    expected_tokens = [
      Calculator::Token.new(:identifier, "sin", 0),
      Calculator::Token.new(:opening_paren, "(", 3),
      Calculator::Token.new(:number, "1.23", 4),
      Calculator::Token.new(:closing_paren, ")", 8),
    ]

    assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
  end

  def test_with_function_call_one_arg_scientific_notation
    input = "sin(1e-2)"
    expected_tokens = [
      Calculator::Token.new(:identifier, "sin", 0),
      Calculator::Token.new(:opening_paren, "(", 3),
      Calculator::Token.new(:number, "1e-2", 4),
      Calculator::Token.new(:closing_paren, ")", 8),
    ]

    assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
  end

  def test_with_function_call_one_arg_identifier
    input = "sin(pi)"
    expected_tokens = [
      Calculator::Token.new(:identifier, "sin", 0),
      Calculator::Token.new(:opening_paren, "(", 3),
      Calculator::Token.new(:identifier, "pi", 4),
      Calculator::Token.new(:closing_paren, ")", 6),
    ]

    assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
  end

  def test_with_function_call_one_arg_expression
    input = "sin((pi * 2) / 180)"
    expected_tokens = [
      Calculator::Token.new(:identifier, "sin", 0),
      Calculator::Token.new(:opening_paren, "(", 3),
      Calculator::Token.new(:opening_paren, "(", 4),
      Calculator::Token.new(:identifier, "pi", 5),
      Calculator::Token.new(:operator, "*", 8),
      Calculator::Token.new(:number, "2", 10),
      Calculator::Token.new(:closing_paren, ")", 11),
      Calculator::Token.new(:operator, "/", 13),
      Calculator::Token.new(:number, "180", 15),
      Calculator::Token.new(:closing_paren, ")", 18),
    ]

    assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
  end

  def test_with_function_call_many_args
    input = "func(1, pi, 1.234, 1e-2, 1 + 2)"
    expected_tokens = [
      Calculator::Token.new(:identifier, "func", 0),
      Calculator::Token.new(:opening_paren, "(", 4),
      Calculator::Token.new(:number, "1", 5),
      Calculator::Token.new(:comma, ",", 6),
      Calculator::Token.new(:identifier, "pi", 8),
      Calculator::Token.new(:comma, ",", 10),
      Calculator::Token.new(:number, "1.234", 12),
      Calculator::Token.new(:comma, ",", 17),
      Calculator::Token.new(:number, "1e-2", 19),
      Calculator::Token.new(:comma, ",", 23),
      Calculator::Token.new(:number, "1", 25),
      Calculator::Token.new(:operator, "+", 27),
      Calculator::Token.new(:number, "2", 29),
      Calculator::Token.new(:closing_paren, ")", 30),
    ]

    assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
  end

  def test_with_valid_expression
    input = "3 + 4 * -2 / ( 1 - 5 ) ^ 2 ^ 3 % 5"
    expected_tokens = [
      Calculator::Token.new(:number, "3", 0),
      Calculator::Token.new(:operator, "+", 2),
      Calculator::Token.new(:number, "4", 4),
      Calculator::Token.new(:operator, "*", 6),
      Calculator::Token.new(:operator, "-", 8),
      Calculator::Token.new(:number, "2", 9),
      Calculator::Token.new(:operator, "/", 11),
      Calculator::Token.new(:opening_paren, "(", 13),
      Calculator::Token.new(:number, "1", 15),
      Calculator::Token.new(:operator, "-", 17),
      Calculator::Token.new(:number, "5", 19),
      Calculator::Token.new(:closing_paren, ")", 21),
      Calculator::Token.new(:operator, "^", 23),
      Calculator::Token.new(:number, "2", 25),
      Calculator::Token.new(:operator, "^", 27),
      Calculator::Token.new(:number, "3", 29),
      Calculator::Token.new(:operator, "%", 31),
      Calculator::Token.new(:number, "5", 33),
    ]

    assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
  end

  def test_with_valid_expression_containing_no_spaces
    input = "3+4*-2/(1-5)^2^3%5"
    expected_tokens = [
      Calculator::Token.new(:number, "3", 0),
      Calculator::Token.new(:operator, "+", 1),
      Calculator::Token.new(:number, "4", 2),
      Calculator::Token.new(:operator, "*", 3),
      Calculator::Token.new(:operator, "-", 4),
      Calculator::Token.new(:number, "2", 5),
      Calculator::Token.new(:operator, "/", 6),
      Calculator::Token.new(:opening_paren, "(", 7),
      Calculator::Token.new(:number, "1", 8),
      Calculator::Token.new(:operator, "-", 9),
      Calculator::Token.new(:number, "5", 10),
      Calculator::Token.new(:closing_paren, ")", 11),
      Calculator::Token.new(:operator, "^", 12),
      Calculator::Token.new(:number, "2", 13),
      Calculator::Token.new(:operator, "^", 14),
      Calculator::Token.new(:number, "3", 15),
      Calculator::Token.new(:operator, "%", 16),
      Calculator::Token.new(:number, "5", 17),
    ]

    assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
  end

  def test_with_valid_expression_containing_decimals
    input = "3.45 + 4e-5 * -2 / ( 1 - 5E+6 ) ^ 2.345678 ^ 3e4 % 5.0"
    expected_tokens = [
      Calculator::Token.new(:number, "3.45", 0),
      Calculator::Token.new(:operator, "+", 5),
      Calculator::Token.new(:number, "4e-5", 7),
      Calculator::Token.new(:operator, "*", 12),
      Calculator::Token.new(:operator, "-", 14),
      Calculator::Token.new(:number, "2", 15),
      Calculator::Token.new(:operator, "/", 17),
      Calculator::Token.new(:opening_paren, "(", 19),
      Calculator::Token.new(:number, "1", 21),
      Calculator::Token.new(:operator, "-", 23),
      Calculator::Token.new(:number, "5E+6", 25),
      Calculator::Token.new(:closing_paren, ")", 30),
      Calculator::Token.new(:operator, "^", 32),
      Calculator::Token.new(:number, "2.345678", 34),
      Calculator::Token.new(:operator, "^", 43),
      Calculator::Token.new(:number, "3e4", 45),
      Calculator::Token.new(:operator, "%", 49),
      Calculator::Token.new(:number, "5.0", 51),
    ]

    assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
  end

  def test_with_valid_expression_containing_identifiers
    input = "sin(hypot(2, 3) / 3 * pi)"
    expected_tokens = [
      Calculator::Token.new(:identifier, "sin", 0),
      Calculator::Token.new(:opening_paren, "(", 3),
      Calculator::Token.new(:identifier, "hypot", 4),
      Calculator::Token.new(:opening_paren, "(", 9),
      Calculator::Token.new(:number, "2", 10),
      Calculator::Token.new(:comma, ",", 11),
      Calculator::Token.new(:number, "3", 13),
      Calculator::Token.new(:closing_paren, ")", 14),
      Calculator::Token.new(:operator, "/", 16),
      Calculator::Token.new(:number, "3", 18),
      Calculator::Token.new(:operator, "*", 20),
      Calculator::Token.new(:identifier, "pi", 22),
      Calculator::Token.new(:closing_paren, ")", 24),
    ]

    assert_equal expected_tokens, Calculator::Scanner.new(input).tokenize
  end

  def test_with_invalid_expression_single_error
    input = "3 + 4 * -2.2.2 / ( 1 - 5 ) ^ 2 ^ 3 % 5"
    expected_err = <<~TEXT.chomp
      illegal character '.':
      3 + 4 * -2.2.2 / ( 1 - 5 ) ^ 2 ^ 3 % 5
                  ^
    TEXT

    err = -> { Calculator::Scanner.new(input).tokenize }
      .must_raise Calculator::Errors::ScannerError
    assert_equal expected_err, err.message
  end

  def test_with_invalid_expression_multiple_errors
    input = "3 + 4 * -2.2.2 / ( 1e*2 - 5pi } ^ 2 & 3 % 5"
    expected_err = <<~TEXT.chomp
      illegal character '.':
      3 + 4 * -2.2.2 / ( 1e*2 - 5pi } ^ 2 & 3 % 5
                  ^
      illegal character '*' in number:
      3 + 4 * -2.2.2 / ( 1e*2 - 5pi } ^ 2 & 3 % 5
                           ^
      illegal character 'p' in number:
      3 + 4 * -2.2.2 / ( 1e*2 - 5pi } ^ 2 & 3 % 5
                                 ^
      illegal character '}':
      3 + 4 * -2.2.2 / ( 1e*2 - 5pi } ^ 2 & 3 % 5
                                    ^
      illegal character '&':
      3 + 4 * -2.2.2 / ( 1e*2 - 5pi } ^ 2 & 3 % 5
                                          ^
    TEXT

    err = -> { Calculator::Scanner.new(input).tokenize }
      .must_raise Calculator::Errors::ScannerError
    assert_equal expected_err, err.message
  end
end
