# Put lib/ on the load path so plain requires and Sequel's extension loader
# (db.extension(:sole) -> require "sequel/extensions/sole") resolve.
$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "domus/app"
require "domus/web"
require "sequel/extensions/migration"

app = Domus::App.new
Sequel::Migrator.run(app.db, "db/migrate") unless Dir.empty?("db/migrate")
Domus::Web.opts[:app] = app

run Domus::Web
