# rbs_inline: enabled

require "sequel"
require_relative "config"

module Domus
  class App
    attr_reader :config, :db

    # : (Config) -> void
    def initialize(config = Domus.config)
      @config = config
      @db = Sequel.sqlite(config.database_url)
      Sequel::Model.db = @db
    end

    # : (Hash[Symbol, untyped]) -> Pathname
    def file_path(record)
      uploads_root / "#{record[:id]}#{record[:extension]}"
    end

    # : () -> Pathname
    def uploads_root = config.storage_path / "uploads"
  end
end
