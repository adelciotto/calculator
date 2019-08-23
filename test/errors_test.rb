require "test_helper"

describe "Calculator::Error" do
  describe "when raised with no error message" do
    it "displays the default error message" do
      raise Calculator::Error
    rescue Calculator::Error => error
      error.message.must_equal "failed to evaluate expression"
    end
  end

  describe "when raised with a custom error message" do
    it "displays the custom error message" do
      raise Calculator::Error, "a custom error message"
    rescue Calculator::Error => error
      error.message.must_equal "a custom error message"
    end
  end
end

describe "Calculator::ParseTokenError" do
  describe "when raised" do
    it "displays the correct error message" do
      raise Calculator::ParseTokenError, "1foobar"
    rescue Calculator::ParseTokenError => error
      error.message.must_equal "failed to parse token 1foobar"
    end
  end
end
