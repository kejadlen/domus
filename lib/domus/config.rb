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

    # Where stored upload blobs live on disk, derived from the storage root.
    #: () -> Pathname
    def uploads_root = storage_path / "uploads"
  end

  class << self
    # The process-wide config, defaulting to the environment the first time
    # it's read. Loaded code reads this single instance: Web's :static plugin
    # needs the storage path at load, and uploads are stored under it.
    #: () -> Config
    def config = @config ||= Config.env

    # Override the config before it's first read. Tests assign a Config
    # pointing at a temp dir; production leaves it unset and falls back to the
    # environment.
    #: (Config) -> void
    def config=(config)
      @config = config
    end
  end
end
