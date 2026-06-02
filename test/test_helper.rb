# frozen_string_literal: true

require "minitest/autorun"

require_relative "../lib/app"
require_relative "../lib/web"

app = Domus::App.new(Domus::Config.new(database_url: ":memory:"))
migrate_dir = File.expand_path("../db/migrate", __dir__)
Sequel::Migrator.run(app.db, migrate_dir) unless Dir.empty?(migrate_dir)
Domus::Web.opts[:app] = app
