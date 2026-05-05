# frozen_string_literal: true

require "rake/testtask"
require_relative "lib/db"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

task default: :test

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
