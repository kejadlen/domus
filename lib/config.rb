# frozen_string_literal: true

class Config < Data.define(:database_url)
  def self.load
    new(database_url: ENV.fetch("DATABASE_URL", "db/domus.db"))
  end
end
