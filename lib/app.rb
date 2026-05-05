# frozen_string_literal: true

require "roda"

class App < Roda
  route do |r|
    r.root do
      "ok"
    end
  end
end
