# frozen_string_literal: true

require_relative "test_helper"
require "rack/test"
require_relative "../lib/app"

class TestApp < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def test_root
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<title>Domus</title>"
    assert_includes last_response.body, "ok"
  end
end
