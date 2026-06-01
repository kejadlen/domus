# frozen_string_literal: true

require "sequel"
require "sequel/extensions/migration"

DB = Sequel.sqlite(ENV.fetch("DATABASE_URL", "db/domus.db"))
