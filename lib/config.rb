# frozen_string_literal: true

module Domus
  class Config < Data.define(:database_url)
    def self.from_env
      new(database_url: ENV.fetch("DATABASE_URL"))
    end
  end
end
