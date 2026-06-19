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

  class << self
    # The process-wide config, resolved from the environment the first time
    # it's read. Loaded code reads this single instance: Web's :static plugin
    # needs the storage path at load, and App stores files there. Tests assign
    # a Config here before requiring the app to point it at a temp dir.
    attr_writer :config

    #: () -> Config
    def config = @config ||= Config.env
  end
end
