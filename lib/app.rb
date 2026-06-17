# frozen_string_literal: true

require "sequel"
require_relative "config"

module Domus
  class App
    attr_reader :config, :db

    def initialize(config = Config.env)
      @config = config
      @db = Sequel.sqlite(config.database_url, foreign_keys: true)
    end

    def file_path(record)
      config.storage_path / "files" / "#{record[:id]}#{record[:extension]}"
    end
  end
end
