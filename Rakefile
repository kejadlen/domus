# frozen_string_literal: true

require "minitest/test_task"
require_relative "lib/app"
require "sequel/extensions/migration"

DOMUS_APP = Domus::App.new
DB = DOMUS_APP.db

desc "Create bundler binstubs (runs when Gemfile.lock changes)"
file ".direnv/.bundled" => ["Gemfile.lock"] do
  sh "bundle binstubs --all"
  touch ".direnv/.bundled"
end

task binstubs: ".direnv/.bundled"

Minitest::TestTask.create(:test)

desc "Generate RBS from inline annotations and run Steep type checker"
task :check do
  sh "rbs-inline --output lib/"
  sh "steep check"
end

task default: %i[test check]

desc "Start dev server"
task :dev do
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

  desc "Seed the database with development data"
  task :seed do
    # Add seed data here
  end
end
