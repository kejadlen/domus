# rbs_inline: enabled

require "sequel"
require_relative "config"

# Put lib/ on the load path so Sequel can find our dataset extensions by name
# (e.g. db.extension(:sole) requires "sequel/extensions/sole").
$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)

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
      config.storage_path / "files" / "#{record[:id]}#{record[:extension]}"
    end
  end
end
