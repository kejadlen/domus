# frozen_string_literal: true

require "ipaddr"

module Domus
  module Middleware
    class IpAllowlist
      # Source: https://sendgrid.com/en-us/blog/smtp-ip-range-sendgrid-2024
      DEFAULT_SENDGRID_IPS = %w[
        167.89.115.0/24
        167.89.114.0/24
        159.183.224.0/20
        159.183.240.0/20
      ].freeze

      def self.allowed?(addr, ips = DEFAULT_SENDGRID_IPS)
        ips.map { |ip| IPAddr.new(ip) }.any? { |range| range.include?(addr) }
      end

      def initialize(app, allowed: nil)
        @app = app
        @allowed = build_allowed(allowed || DEFAULT_SENDGRID_IPS)
      end

      def call(env)
        addr = env["REMOTE_ADDR"]
        return [403, {}, ["Forbidden"]] unless addr && allowed?(addr)

        @app.call(env)
      end

      private

      def build_allowed(ips)
        ips.map { |ip| IPAddr.new(ip) }
      end

      def allowed?(addr)
        @allowed.any? { |range| range.include?(addr) }
      end
    end
  end
end
