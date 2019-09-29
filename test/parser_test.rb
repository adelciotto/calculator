require "test_helper"

class TestParser < Minitest::Test
  def test_with_no_input
    expected_err = "no EOF token"

    err = assert_raises Calculator::Errors::ParserError do
      Calculator::Parser.new.parse
    end
    assert_equal expected_err, err.message
  end

  def test_with_no_tokens
    expected_err = "no EOF token"

    err = assert_raises Calculator::Errors::ParserError do
      Calculator::Parser.new([]).parse
    end
    assert_equal expected_err, err.message
  end

  def test_with_eof_tokens
    assert_equal [], Calculator::Parser.new([Calculator::Token.new(:eof, "", 0)]).parse
  end

  def test_with_number_token
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:eof, "", 0),
    ]
    expected_result = [Calculator::PostfixNode.new(:number, 1, 0)]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_identifier_constant
    input_tokens = [
      Calculator::Token.new(:identifier, "pi", 0),
      Calculator::Token.new(:eof, "", 2),
    ]
    expected_result = [Calculator::PostfixNode.new(:constant, :pi, 0)]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_identifier_function
    input_tokens = [
      Calculator::Token.new(:identifier, "sin", 0),
      Calculator::Token.new(:opening_paren, "(", 4),
      Calculator::Token.new(:identifier, "pi", 5),
      Calculator::Token.new(:closing_paren, ")", 7),
      Calculator::Token.new(:eof, "", 7),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:end_function, "", 0),
      Calculator::PostfixNode.new(:constant, :pi, 5),
      Calculator::PostfixNode.new(:function, :sin, 0),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_unary_operator
    input_tokens = [
      Calculator::Token.new(:operator, "-", 0),
      Calculator::Token.new(:number, "1", 1),
      Calculator::Token.new(:operator, "+", 4),
      Calculator::Token.new(:number, "2", 6),
      Calculator::Token.new(:eof, "", 6),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1, 1),
      Calculator::OperatorNode.new(:unary_operator, :-, 0),
      Calculator::PostfixNode.new(:number, 2, 6),
      Calculator::OperatorNode.new(:binary_operator, :+, 4),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_plus
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "+", 2),
      Calculator::Token.new(:number, "2", 4),
      Calculator::Token.new(:eof, "", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1, 0),
      Calculator::PostfixNode.new(:number, 2, 4),
      Calculator::OperatorNode.new(:binary_operator, :+, 2),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_minus
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "-", 2),
      Calculator::Token.new(:number, "2", 4),
      Calculator::Token.new(:eof, "", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1, 0),
      Calculator::PostfixNode.new(:number, 2, 4),
      Calculator::OperatorNode.new(:binary_operator, :-, 2),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_multiply
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "*", 2),
      Calculator::Token.new(:number, "2", 4),
      Calculator::Token.new(:eof, "", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1, 0),
      Calculator::PostfixNode.new(:number, 2, 4),
      Calculator::OperatorNode.new(:binary_operator, :*, 2),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_divide
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "/", 2),
      Calculator::Token.new(:number, "2", 4),
      Calculator::Token.new(:eof, "", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1, 0),
      Calculator::PostfixNode.new(:number, 2, 4),
      Calculator::OperatorNode.new(:binary_operator, :/, 2),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_modulus
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "%", 2),
      Calculator::Token.new(:number, "2", 4),
      Calculator::Token.new(:eof, "", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1, 0),
      Calculator::PostfixNode.new(:number, 2, 4),
      Calculator::OperatorNode.new(:binary_operator, :%, 2),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_power
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "^", 2),
      Calculator::Token.new(:number, "2", 4),
      Calculator::Token.new(:eof, "", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1, 0),
      Calculator::PostfixNode.new(:number, 2, 4),
      Calculator::OperatorNode.new(:binary_operator, :^, 2),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_valid_expression
    input_tokens = [
      Calculator::Token.new(:number, "3", 0),
      Calculator::Token.new(:operator, "+", 2),
      Calculator::Token.new(:number, "4", 4),
      Calculator::Token.new(:operator, "*", 6),
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
      Calculator::Token.new(:eof, "", 33),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 3, 0),
      Calculator::PostfixNode.new(:number, 4, 4),
      Calculator::PostfixNode.new(:number, 2, 9),
      Calculator::OperatorNode.new(:binary_operator, :*, 6),
      Calculator::PostfixNode.new(:number, 1, 15),
      Calculator::PostfixNode.new(:number, 5, 19),
      Calculator::OperatorNode.new(:binary_operator, :-, 17),
      Calculator::PostfixNode.new(:number, 2, 25),
      Calculator::PostfixNode.new(:number, 3, 29),
      Calculator::OperatorNode.new(:binary_operator, :^, 27),
      Calculator::OperatorNode.new(:binary_operator, :^, 23),
      Calculator::OperatorNode.new(:binary_operator, :/, 11),
      Calculator::PostfixNode.new(:number, 5, 33),
      Calculator::OperatorNode.new(:binary_operator, :%, 31),
      Calculator::OperatorNode.new(:binary_operator, :+, 2),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end
end
