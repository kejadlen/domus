# frozen_string_literal: true

require "sequel"
require "sequel/extensions/migration"
require_relative "config"

DB = Sequel.sqlite(Config.load.database_url)
