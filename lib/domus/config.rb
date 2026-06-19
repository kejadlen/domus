# rbs_inline: enabled

require "pathname"

module Domus
  Config = Data.define(
    :database_url, #: String
    :storage_path #: Pathname
  )

  class Config
    #: () -> Config
    def self.env = new(
      database_url: ENV.fetch("DATABASE_URL") { "db/domus.db" },
      storage_path: Pathname(ENV.fetch("STORAGE_PATH") { "storage" }),
    )
  end
end
