# Put lib/ on the load path so plain requires and Sequel's plugin loader
# (Sequel::Model.plugin :sole -> require "sequel/plugins/sole") resolve.
$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "domus/app"
require "domus/web"
require "sequel/extensions/migration"

app = Domus::App.new
Sequel::Migrator.run(app.db, "db/migrate") unless Dir.empty?("db/migrate")

# Models reflect on their tables at class-load time, so they must be required
# only after migrations have run.
require "domus/models"

Domus::Web.opts[:app] = app

run Domus::Web
