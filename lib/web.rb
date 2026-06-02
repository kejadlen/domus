# frozen_string_literal: true

require "roda"
require_relative "views/layout"
require_relative "ingest_email"
require_relative "middleware/ip_allowlist"

module Domus
  class Web < Roda
    route do |r|
      r.root do
        render_with_layout { "ok" }
      end

      r.post "inbound/email" do
        ip = request.env["REMOTE_ADDR"]
        unless ip && Middleware::IpAllowlist.allowed?(ip)
          response.status = 403
          next "Forbidden"
        end
        IngestEmail.handle(self)
      end
    end

    private

    def db = opts[:db] || opts[:app].db

    def render_with_layout(&block)
      Views::Layout.new(&block).call
    end
  end
end
