require "minitest/autorun"
require "sequel"
require "sequel/extensions/migration"
require "fileutils"
require "pathname"

storage = Dir.mktmpdir("domus-test")
at_exit { FileUtils.rm_rf(storage) }
ENV["DATABASE_URL"] = ":memory:"
ENV["STORAGE_PATH"] = storage

require "domus/web"
require "domus/seeds"

migrate_dir = File.expand_path("../db/migrate", __dir__)
Sequel::Migrator.run(Domus::Web.opts[:app].db, migrate_dir) unless Dir.empty?(migrate_dir)
