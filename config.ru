# Put lib/ on the load path so plain requires and Sequel's extension loader
# (db.extension(:sole) -> require "sequel/extensions/sole") resolve.
$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "domus/app"
require "domus/web"
require "sequel/extensions/migration"

app = Domus::App.new
Sequel::Migrator.run(app.db, "db/migrate") unless Dir.empty?("db/migrate")
Domus::Web.opts[:app] = app

# Serve stored uploads (storage/files/{id}{ext}) at /files/ straight off disk.
# Uploads are immutable once stored, so they cache indefinitely.
Domus::Web.plugin :static, ["/files/"],
  root: app.config.storage_path.to_s,
  cache_control: "private, max-age=31536000, immutable"

run Domus::Web
