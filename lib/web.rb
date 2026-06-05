# frozen_string_literal: true

require "roda"
require_relative "views/layout"

module Domus
  class Web < Roda
    route do |r|
      r.root do
        render_with_layout { "ok" }
      end
    end

    private

    def db = opts[:db] || opts[:app].db

    def render_with_layout(&block)
      Views::Layout.new(&block).call
    end
  end
end
