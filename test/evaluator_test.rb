require "test_helper"

class TestParser < Minitest::Test
  def test_with_no_input
    assert_equal 0, Calculator::Evaluator.new.eval
  end

  def test_with_no_postfix_nodes
    assert_equal 0, Calculator::Evaluator.new([]).eval
  end

  def test_with_operator_expression
    postfix_nodes = [
      Calculator::PostfixNode.new(:number, 3),
      Calculator::PostfixNode.new(:number, 4),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::OperatorNode.new(:unary_operator, :-),
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

    assert_in_delta 7.9998779296875, Calculator::Evaluator.new(postfix_nodes).eval
  end

  def test_with_function_expression
    postfix_nodes = [
      Calculator::PostfixNode.new(:end_function, ""),
      Calculator::PostfixNode.new(:end_function, ""),
      Calculator::PostfixNode.new(:number, 2),
      Calculator::PostfixNode.new(:number, 3),
      Calculator::PostfixNode.new(:function, :atan2),
      Calculator::PostfixNode.new(:number, 3),
      Calculator::OperatorNode.new(:binary_operator, :/),
      Calculator::PostfixNode.new(:constant, :pi),
      Calculator::OperatorNode.new(:binary_operator, :*),
      Calculator::PostfixNode.new(:function, :sin),
    ]

    assert_in_delta 0.5775749291108316, Calculator::Evaluator.new(postfix_nodes).eval
  end

  def test_with_divide_by_zero
    tests = [
      [
        Calculator::PostfixNode.new(:number, 1),
        Calculator::PostfixNode.new(:number, 0),
        Calculator::OperatorNode.new(:binary_operator, :/),
      ],
      [
        Calculator::PostfixNode.new(:number, 1),
        Calculator::PostfixNode.new(:number, 2),
        Calculator::PostfixNode.new(:number, 2),
        Calculator::OperatorNode.new(:binary_operator, :-),
        Calculator::OperatorNode.new(:binary_operator, :/),
      ],
    ]
    expected_err = "division by zero"

    tests.each do |input|
      err = assert_raises Calculator::Errors::EvaluatorError do
        Calculator::Evaluator.new(input).eval
      end
      assert_includes err.message, expected_err
    end
  end
  
  def test_with_invalid_operands
    postfix_nodes = [
        Calculator::PostfixNode.new(:number, 1),
        Calculator::OperatorNode.new(:binary_operator, :+),
        Calculator::OperatorNode.new(:binary_operator, :*),
    ]
    expected_err = "invalid operands provided to operator +"

    err = assert_raises Calculator::Errors::EvaluatorError do
      Calculator::Evaluator.new(postfix_nodes).eval
    end
    assert_includes err.message, expected_err
  end

  def test_with_too_few_function_arguments
    postfix_nodes = [
      Calculator::PostfixNode.new(:end_function, ""),
      Calculator::PostfixNode.new(:function, :sin),
    ]
    expected_err = "incorrect number of args provided to function"

    err = assert_raises Calculator::Errors::EvaluatorError do
      Calculator::Evaluator.new(postfix_nodes).eval
    end
    assert_includes err.message, expected_err
  end

  def test_with_too_many_function_arguments
    postfix_nodes = [
        Calculator::PostfixNode.new(:end_function, ""),
        Calculator::PostfixNode.new(:number, 1),
        Calculator::PostfixNode.new(:number, 2),
        Calculator::PostfixNode.new(:function, :sin),
    ]
    expected_err = "incorrect number of args provided to function"

    err = assert_raises Calculator::Errors::EvaluatorError do
      Calculator::Evaluator.new(postfix_nodes).eval
    end
    assert_includes err.message, expected_err
  end
end
