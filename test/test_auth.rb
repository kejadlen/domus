# frozen_string_literal: true

require_relative "test_helper"
require "rack/test"
require_relative "../lib/middleware/auth"

class TestAuth < Minitest::Test
  include Rack::Test::Methods

  def app
    inner = proc { |env| [200, {}, ["hello #{env['domus.user']}"]] }
    Domus::Middleware::Auth.new(inner)
  end

  def test_allows_request_with_header
    get "/", {}, { "HTTP_X_FORWARDED_USER" => "alice" }
    assert_equal 200, last_response.status
    assert_equal "hello alice", last_response.body
  end

  def test_rejects_request_without_header
    get "/"
    assert_equal 401, last_response.status
    assert_equal "Unauthorized", last_response.body
  end
end
