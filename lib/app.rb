# rbs_inline: enabled

require "sequel"
require_relative "config"

module Domus
  class App
    attr_reader :config, :db

    # : (Config) -> void
    def initialize(config = Config.env)
      @config = config
      @db = Sequel.sqlite(config.database_url)
      @db.extension(:sole)
    end

    # : (Hash[Symbol, untyped]) -> Pathname
    def file_path(record)
      files_root / "#{record[:id]}#{record[:extension]}"
    end

    def files_root = config.storage_path / "files"
  end
end
