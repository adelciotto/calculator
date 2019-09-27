require "test_helper"

class TestParser < Minitest::Test
  def test_with_no_input
    assert_equal [], Calculator::Parser.new.parse
  end

  def test_with_no_tokens
    assert_equal [], Calculator::Parser.new([]).parse
  end

  def test_with_number_token
    input_tokens = [Calculator::Token.new(:number, "1", 0)]
    expected_result = [Calculator::PostfixNode.new(:number, 1)]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_identifier_constant
    input_tokens = [Calculator::Token.new(:identifier, "pi", 0)]
    expected_result = [Calculator::PostfixNode.new(:constant, :pi)]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_identifier_function
    input_tokens = [
      Calculator::Token.new(:identifier, "sin", 0),
      Calculator::Token.new(:opening_paren, "(", 4),
      Calculator::Token.new(:identifier, "pi", 5),
      Calculator::Token.new(:closing_paren, ")", 7),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:constant, :pi),
      Calculator::PostfixNode.new(:function, :sin),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_unary_operator
    input_tokens = [
      Calculator::Token.new(:operator, "-", 0),
      Calculator::Token.new(:number, "1", 1),
      Calculator::Token.new(:operator, "+", 4),
      Calculator::Token.new(:number, "2", 6),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1),
      Calculator::OperatorNode.new(:unary_operator, :-),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::OperatorNode.new(:binary_operator, :+),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_plus
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "+", 2),
      Calculator::Token.new(:number, "2", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::OperatorNode.new(:binary_operator, :+),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_minus
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "-", 2),
      Calculator::Token.new(:number, "2", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::OperatorNode.new(:binary_operator, :-),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_multiply
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "*", 2),
      Calculator::Token.new(:number, "2", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::OperatorNode.new(:binary_operator, :*),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_divide
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "/", 2),
      Calculator::Token.new(:number, "2", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::OperatorNode.new(:binary_operator, :/),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_modulus
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "%", 2),
      Calculator::Token.new(:number, "2", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::OperatorNode.new(:binary_operator, :%),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end

  def test_with_binary_operator_power
    input_tokens = [
      Calculator::Token.new(:number, "1", 0),
      Calculator::Token.new(:operator, "^", 2),
      Calculator::Token.new(:number, "2", 4),
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 1),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::OperatorNode.new(:binary_operator, :^),
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
    ]
    expected_result = [
      Calculator::PostfixNode.new(:number, 3),
      Calculator::PostfixNode.new(:number, 4),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::OperatorNode.new(:binary_operator, :*),
      Calculator::PostfixNode.new(:number, 1),
      Calculator::PostfixNode.new(:number, 5),
      Calculator::OperatorNode.new(:binary_operator, :-),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::PostfixNode.new(:number, 3),
      Calculator::OperatorNode.new(:binary_operator, :^),
      Calculator::OperatorNode.new(:binary_operator, :^),
      Calculator::OperatorNode.new(:binary_operator, :/),
      Calculator::PostfixNode.new(:number, 5),
      Calculator::OperatorNode.new(:binary_operator, :%),
      Calculator::OperatorNode.new(:binary_operator, :+),
    ]

    assert_equal expected_result, Calculator::Parser.new(input_tokens).parse
  end
end
