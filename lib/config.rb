# rbs_inline: enabled
# frozen_string_literal: true

module Domus
  Config = Data.define(
    :database_url, #: String
    :storage_path #: String
  )

  class Config
    #: () -> Config
    def self.env = new(
      database_url: ENV.fetch("DATABASE_URL") { "db/domus.db" },
      storage_path: ENV.fetch("STORAGE_PATH") { "storage" },
    )
  end
end
