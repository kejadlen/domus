---
name: sequel
description: "Use this skill when working on Domus's database layer — the Sequel connection in lib/app.rb, models in lib/models.rb, and migrations in db/migrate/. Triggers: adding or rolling back a migration, defining a model, writing dataset queries/inserts, wrapping work in a transaction, or reasoning about the schema (documents, files, assets, asset_attachments). Domus uses Sequel 5.x against SQLite via the sqlite3 gem."
---

# Sequel database

Domus persists data with [Sequel](https://sequel.jeremyevans.net) 5.104 on
SQLite. The connection is opened once in `lib/app.rb` and threaded through the
Roda app's `opts`.

## Connection

```ruby
# lib/app.rb
@db = Sequel.sqlite(config.database_url)   # file path, or ":memory:" in tests
```

`App#db` is the `Sequel::Database`. Routes reach it via `app.db` (see the
**roda** skill). Tests build an `App` with `database_url: ":memory:"` and run
migrations into it (`test/test_helper.rb`). A `:memory:` database is private to
its single connection — fine for the test suite's one-connection use.

> **SQLite foreign keys are OFF by default.** Sequel doesn't enable them unless
> you pass `foreign_keys: true` to `Sequel.sqlite`. So the `foreign_key`
> columns in the schema document intent and create indexes, but SQLite is not
> currently enforcing referential integrity at runtime. Keep that in mind
> before relying on cascade/restrict behavior.

## Schema

Four tables (see `db/migrate/`):

- **`documents`** — `path`, `kind`, `received_at`, `created_at`.
- **`files`** — `extension`, `created_at`. One row per stored image blob; the
  blob itself lives on disk at `App#file_path`.
- **`assets`** — `name`, `created_at`.
- **`asset_attachments`** — join table, composite PK `[asset_id, file_id]`,
  both `foreign_key`s, plus `created_at`.

## Migrations

Plain Sequel migrations, numbered `NNN_description.rb`, in `db/migrate/`. The
leading integers mean Domus uses the **IntegerMigrator** (sequential, no
duplicates) — not timestamped migrations. Use the **`change`** block; Sequel
reverses it automatically on rollback:

```ruby
# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:assets) do
      primary_key :id
      String   :name, null: false
      DateTime :created_at, null: false
    end
  end
end
```

Column DSL (Ruby type names map to SQL types):

- `primary_key :id` — auto-increment integer PK.
- `String :name` (→ varchar), `DateTime :created_at`, `Integer :n`.
- `foreign_key :asset_id, :assets` — FK column referencing `assets(id)`.
- `primary_key [:asset_id, :file_id]` — composite PK (see migration 004).
- Modifiers: `null: false`, `default:`, `unique: true`, `index: true`.

Conventions in this repo: every column is `null: false` unless genuinely
optional, and every table carries a `created_at DateTime`. Name the next file
with the next zero-padded number.

**`change` can't auto-reverse everything.** It reverses `create_table`,
`add_column`, `add_index`, `rename_*`, etc. For data backfills or raw SQL,
write explicit `up`/`down` blocks instead — `change` will raise if it can't
figure out the inverse. Also: don't reference `Sequel::Model` classes in
migrations; use the dataset API so a migration keeps working as models evolve.

### Running migrations

- **`rake db:migrate`** — apply pending migrations.
- **`rake db:rollback`** — revert the last one (it looks up the latest row in
  `schema_migrations` and migrates back one step).
- `config.ru` runs `Sequel::Migrator.run(app.db, "db/migrate")` on boot, so
  deploys self-migrate.

## Datasets

Most queries go through datasets (`db[:table]`), not models. Datasets are
**frozen and chainable** — each method returns a new dataset, so they're
reusable and thread-safe; nothing executes until a terminal method is called.

```ruby
# building (lazy, returns datasets)
recent = db[:files].where { created_at > Time.now - 86400 }.order(Sequel.desc(:created_at))

# terminal (executes, returns data)
file_id = db[:files].insert(extension: ext, created_at: Time.now)  # => new id
rows    = db[:files].all                                           # => [Hash, …]
one     = db[:files].first                                         # => Hash | nil
count   = db[:files].count
db[:assets].delete                                                 # truncate (test setup)
latest  = db[:schema_migrations].order(Sequel.desc(:filename)).limit(1).get(:filename)
```

Helpers: `where` / `exclude` (Hash, block, or `Sequel.lit`), `select`,
`order` with `Sequel.desc`/`Sequel.asc`, `limit`, `.get(:col)` for one value,
`.update(col: val)`, `.delete`.

**SQL-injection safety:** pass conditions as hashes/blocks — Sequel
parameterizes them. If you must drop to literal SQL, use placeholders
(`db[:t].where(Sequel.lit("x = ?", input))`), never string interpolation, and
never feed user input to `Sequel.lit` as part of the SQL text.

## Transactions

Wrap multi-statement writes so they commit or roll back together:

```ruby
db.transaction do
  file_id  = db[:files].insert(extension: ext, created_at: Time.now)
  asset_id = db[:assets].insert(name: name, created_at: now)
  db[:asset_attachments].insert(asset_id:, file_id:, created_at: now)
end
```

Any exception rolls the transaction back and re-raises; raise
`Sequel::Rollback` to abort *silently* (no exception escapes). The file-upload
path in `lib/web.rb` does exactly this — DB rows and the on-disk blob are
written inside one transaction. Nested `db.transaction` calls join the outer
transaction by default; pass `savepoint: true` for a real savepoint.

## Models

`Sequel::Model` subclasses live in `lib/models.rb` and infer their table from
the class name (`Document` → `documents`):

```ruby
module Domus
  class Document < Sequel::Model
  end
end
```

Models add associations (`many_to_one`, `one_to_many`, `many_to_many`),
validations (override `#validate` or use the `validation_helpers` plugin),
lifecycle hooks, and reusable scopes via `dataset_module`. Domus's models are
bare today — reach for the dataset API for new query code unless you
specifically need that model behavior, and remember the model's table must
already exist (it reflects on the schema at load time).

## Testing

`test_helper.rb` migrates a fresh `:memory:` database; `test_app.rb` clears
tables in `setup` (`db[:assets].delete`) and asserts against dataset reads
(`db[:files].all`, `.count`). Follow that pattern — assert on the dataset, not
on raw SQL.
