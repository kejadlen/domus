# frozen_string_literal: true

module Domus
  module Middleware
    class Auth
      def initialize(app, header: "X-Forwarded-User")
        @app = app
        @header = header
      end

      def call(env)
        user = env["HTTP_#{header_name}"]
        return [401, {}, ["Unauthorized"]] unless user

        env["domus.user"] = user
        @app.call(env)
      end

      private

      def header_name
        @header.upcase.tr("-", "_")
      end
    end
  end
end
