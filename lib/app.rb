# rbs_inline: enabled

require "sequel"
require_relative "config"
require_relative "sequel/extensions/sole"

module Domus
  class App
    attr_reader :config, :db

    # : (Config) -> void
    def initialize(config = Config.env)
      @config = config
      @db = Sequel.sqlite(config.database_url)
      @db.extend_datasets(Sequel::Sole::DatasetMethods)
    end

    # : (Hash[Symbol, untyped]) -> Pathname
    def file_path(record)
      config.storage_path / "files" / "#{record[:id]}#{record[:extension]}"
    end
  end
end
