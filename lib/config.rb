# rbs_inline: enabled
# frozen_string_literal: true

module Domus
  Config = Data.define(
    :database_url, #: String
  )

  class Config
    #: () -> Config
    def self.env = new(database_url: ENV.fetch("DATABASE_URL") { "db/domus.db" })
  end
end
