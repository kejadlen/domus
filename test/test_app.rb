# frozen_string_literal: true

require_relative "test_helper"
require "rack/test"

class TestApp < Minitest::Test
  include Rack::Test::Methods

  def app
    Domus::Web
  end

  def test_root
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Domus"
    assert_includes last_response.body, "Add a document"
  end
end
