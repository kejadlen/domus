require "minitest/autorun"
require "sequel"
require "sequel/extensions/migration"
require "fileutils"
require "tmpdir"

storage = Dir.mktmpdir("domus-test")
at_exit { FileUtils.rm_rf(storage) }

# Drive config through the environment, the same way production does, before
# anything reads Domus.config: an in-memory database and a temp storage dir.
ENV["DATABASE_URL"] = ":memory:"
ENV["STORAGE_PATH"] = storage

require "domus/db"
migrate_dir = File.expand_path("../db/migrate", __dir__)
Sequel::Migrator.run(Domus::DB, migrate_dir) unless Dir.empty?(migrate_dir)

# Models reflect on their tables at class-load time, so they must be required
# only after migrations have run. Requiring the web app pulls them in.
require "domus/web"
require "domus/seeds"
