# frozen_string_literal: true

require "minitest/test_task"

require_relative "lib/db"

BUNDLE_INSTALL_MARKER = Pathname.new(".bundle/installed")

file BUNDLE_INSTALL_MARKER do
  sh "bundle install"
  sh "bundle binstubs --all"
  mkdir_p BUNDLE_INSTALL_MARKER.dirname
  touch BUNDLE_INSTALL_MARKER
end

task setup: BUNDLE_INSTALL_MARKER

Minitest::TestTask.create(:test)

task default: :test

desc "Start dev server with pre-seeded in-memory database"
task :dev do
  Sequel::Migrator.run(DB, "db/migrate") unless Dir.empty?("db/migrate")

  require "rack"
  Rack::Server.start(config: "config.ru", Port: 9292)
end

namespace :db do
  desc "Run pending migrations"
  task :migrate do
    if Dir.empty?("db/migrate")
      puts "No migrations."
    else
      Sequel::Migrator.run(DB, "db/migrate")
      puts "Migrated."
    end
  end

  desc "Rollback the last migration"
  task :rollback do
    version = DB[:schema_migrations].order(Sequel.desc(:filename)).limit(1).get(:filename)
    if version
      Sequel::Migrator.run(DB, "db/migrate", target: 0, current: version.sub(/\.rb$/, ""))
      puts "Rolled back #{version}."
    else
      puts "Nothing to rollback."
    end
  end
end
