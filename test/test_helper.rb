require "minitest/autorun"
require "sequel"
require "sequel/extensions/migration"
require "fileutils"
require "pathname"

require_relative "../lib/app"
require_relative "../lib/web"

storage = Dir.mktmpdir("domus-test")
at_exit { FileUtils.rm_rf(storage) }

app = Domus::App.new(Domus::Config.new(database_url: ":memory:", storage_path: Pathname(storage)))
migrate_dir = File.expand_path("../db/migrate", __dir__)
Sequel::Migrator.run(app.db, migrate_dir) unless Dir.empty?(migrate_dir)
Domus::Web.opts[:app] = app
Domus::Web.plugin :static, ["/files/"],
  root: app.config.storage_path.to_s,
  cache_control: "private, max-age=31536000, immutable"
