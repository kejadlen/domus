require "minitest/autorun"
require "sequel"
require "sequel/extensions/migration"
require "fileutils"
require "pathname"
require "tmpdir"

require "domus/config"

storage = Dir.mktmpdir("domus-test")
at_exit { FileUtils.rm_rf(storage) }

# Point config at an in-memory database and a temp storage dir before anything
# reads it (db.rb opens the connection at require time, Web's :static plugin
# reads the storage path at load).
Domus.config = Domus::Config.new(database_url: ":memory:", storage_path: Pathname(storage))

require "domus/db"
migrate_dir = File.expand_path("../db/migrate", __dir__)
Sequel::Migrator.run(Domus::DB, migrate_dir) unless Dir.empty?(migrate_dir)

# Models reflect on their tables at class-load time, so they must be required
# only after migrations have run. Requiring the web app pulls them in.
require "domus/web"
require "domus/seeds"
