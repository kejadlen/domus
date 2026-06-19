# Put lib/ on the load path so plain requires and Sequel's extension loader
# (db.extension(:sole) -> require "sequel/extensions/sole") resolve.
$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "domus/web"
require "sequel/extensions/migration"

Sequel::Migrator.run(Domus::Web::APP.db, "db/migrate") unless Dir.empty?("db/migrate")

run Domus::Web
