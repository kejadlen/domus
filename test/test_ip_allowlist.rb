# frozen_string_literal: true

require_relative "test_helper"
require "rack/test"
require_relative "../lib/middleware/ip_allowlist"

class TestIpAllowlist < Minitest::Test
  include Rack::Test::Methods

  def app
    inner = proc { |env| [200, {}, ["ok"]] }
    Domus::Middleware::IpAllowlist.new(inner, allowed: ["167.89.115.0/24"])
  end

  def test_allows_request_from_listed_ip
    get "/", {}, { "REMOTE_ADDR" => "167.89.115.100" }
    assert_equal 200, last_response.status
  end

  def test_blocks_request_from_unlisted_ip
    get "/", {}, { "REMOTE_ADDR" => "10.0.0.1" }
    assert_equal 403, last_response.status
  end

  def test_blocks_request_without_remote_addr
    get "/"
    assert_equal 403, last_response.status
  end


end
