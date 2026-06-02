# frozen_string_literal: true

module Domus
  class Config < Data.define(:database_url)
    def self.env = new(database_url: ENV.fetch("DATABASE_URL") { "db/domus.db" })
  end
end
