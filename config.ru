# Put lib/ on the load path so Sequel can load our dataset extensions by name
# (e.g. db.extension(:sole) -> require "sequel/extensions/sole"). `rake test`
# already adds lib/ for the test run.
$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require_relative "lib/app"
require_relative "lib/web"
require "sequel/extensions/migration"

app = Domus::App.new
Sequel::Migrator.run(app.db, "db/migrate") unless Dir.empty?("db/migrate")
Domus::Web.opts[:app] = app

run Domus::Web
