require "minitest/autorun"
require "sequel"
require "sequel/extensions/migration"
require "fileutils"
require "pathname"

require "domus/app"

storage = Dir.mktmpdir("domus-test")
at_exit { FileUtils.rm_rf(storage) }

# Web reads Domus.config at load to configure static upload serving, so inject
# a temp-dir config before requiring it.
Domus.config = Domus::Config.new(database_url: ":memory:", storage_path: Pathname(storage))

require "domus/web"
require "domus/seeds"

app = Domus::App.new
migrate_dir = File.expand_path("../db/migrate", __dir__)
Sequel::Migrator.run(app.db, migrate_dir) unless Dir.empty?(migrate_dir)
Domus::Web.opts[:app] = app
