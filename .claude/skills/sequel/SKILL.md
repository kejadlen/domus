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
migrations into it (`test/test_helper.rb`).

## Schema

Four tables (see `db/migrate/`):

- **`documents`** — `path`, `kind`, `received_at`, `created_at`.
- **`files`** — `extension`, `created_at`. One row per stored image blob;
  the blob lives on disk at `App#file_path`.
- **`assets`** — `name`, `created_at`.
- **`asset_attachments`** — join table, composite PK `[asset_id, file_id]`,
  both `foreign_key`s, plus `created_at`.

## Migrations

Plain Sequel migrations, numbered `NNN_description.rb`, in `db/migrate/`. Use
the **`change`** block (Sequel reverses it automatically for rollback):

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

Column helpers are Ruby type names: `String`, `DateTime`, `Integer`,
`primary_key`, `foreign_key :asset_id, :assets`. For a composite key use
`primary_key [:asset_id, :file_id]` (see `004_create_asset_attachments.rb`).

Conventions:
- Always `null: false` unless a column is genuinely optional.
- Give every table a `created_at DateTime`.
- Name the next file with the next zero-padded number.

### Running migrations

- **`rake db:migrate`** — apply pending migrations.
- **`rake db:rollback`** — revert the last one.
- `config.ru` also runs `Sequel::Migrator.run(app.db, "db/migrate")` on boot,
  so deploys self-migrate.

## Datasets

Most queries go through datasets (`db[:table]`), not models. The dataset API
is chainable and returns plain hashes:

```ruby
file_id = db[:files].insert(extension: ext, created_at: Time.now)
rows    = db[:files].all
count   = db[:files].count
db[:assets].delete                                   # truncate (used in test setup)
db[:schema_migrations].order(Sequel.desc(:filename)).limit(1).get(:filename)
```

Use `Sequel.desc(:col)` / `Sequel.asc(:col)` for ordering, `.get(:col)` to
pull a single value, `.where(...)` to filter.

## Transactions

Wrap multi-statement writes so they commit or roll back together:

```ruby
db.transaction do
  file_id  = db[:files].insert(extension: ext, created_at: Time.now)
  asset_id = db[:assets].insert(name: name, created_at: now)
  db[:asset_attachments].insert(asset_id:, file_id:, created_at: now)
end
```

The file-upload path in `lib/web.rb` does exactly this — DB rows and the
on-disk blob are written inside one transaction.

## Models

`Sequel::Model` subclasses live in `lib/models.rb` and infer their table from
the class name (`Document` → `documents`):

```ruby
module Domus
  class Document < Sequel::Model
  end
end
```

Models are sparse today — reach for the dataset API for new query code unless
you specifically need model behavior (associations, validations, hooks).

## Testing

`test_helper.rb` migrates a fresh `:memory:` database; `test_app.rb` clears
tables in `setup` (`db[:assets].delete`) and asserts against dataset reads
(`db[:files].all`, `.count`). Follow that pattern — assert on the dataset,
not on raw SQL.
