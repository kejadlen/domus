# frozen_string_literal: true

require "sequel"
require "sequel/extensions/migration"

DB = Sequel.connect("sqlite://db/domus.db")
