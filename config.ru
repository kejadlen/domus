# Put lib/ on the load path so plain requires and Sequel's plugin loader
# (Sequel::Model.plugin :sole -> require "sequel/plugins/sole") resolve.
$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "domus/db"
require "sequel/extensions/migration"

Sequel::Migrator.run(Domus::DB, "db/migrate") unless Dir.empty?("db/migrate")

# Models reflect on their tables at class-load time, so they must be required
# only after migrations have run. Requiring the web app pulls them in.
require "domus/web"

run Domus::Web
