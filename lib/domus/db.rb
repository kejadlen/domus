# rbs_inline: enabled

require "sequel"
require_relative "config"

module Domus
  # The process-wide database connection, opened once from the environment
  # config. Requiring this file connects as a side effect, so models and the
  # web app can require it and reach a live Sequel::Database via Domus::DB.
  DB = Sequel.sqlite(config.database_url) #: Sequel::Database
end

Sequel::Model.db = Domus::DB
