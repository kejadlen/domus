# frozen_string_literal: true

require "sequel"
require "sequel/extensions/migration"

require_relative "config"

module Domus
  DB = Sequel.sqlite(Config.from_env.database_url)
end
