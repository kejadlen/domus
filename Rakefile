# Put lib/ on the load path so plain requires and Sequel's extension loader
# (db.extension(:sole) -> require "sequel/extensions/sole") resolve. The test
# task adds lib/ for the spawned test run, but this Rakefile also builds an App
# at load time for the db: tasks, which runs in the bare rake process.
$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "minitest/test_task"
require "app"
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

desc "Start dev server with live reload (needs fd + entr)"
task dev: %w[db:migrate db:seed] do
  # Watch the Ruby/template/asset sources and restart rackup on change. fd is
  # scoped to lib/ and public/ (plus config.ru) so downloaded seed images and
  # vendored gems don't trip the reloader.
  sh "{ fd -e rb -e ru -e css -e svg . lib public; echo config.ru; } | entr -r bundle exec rackup -p 9292"
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
    require "seeds"
    puts Domus::Seeds.call(DOMUS_APP) ? "Seeded." : "Already seeded."
  end
end
