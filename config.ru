# frozen_string_literal: true

require_relative "lib/app"
require_relative "lib/web"
require "sequel/extensions/migration"

app = Domus::App.new
Sequel::Migrator.run(app.db, "db/migrate") unless Dir.empty?("db/migrate")
Domus::Web.opts[:app] = app

run Domus::Web
