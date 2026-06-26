# Switch DB access from datasets to Sequel models

Date: 2026-06-25
Task: `yn` — Switch DB access from datasets to Sequel models

## Goal

Replace Domus's raw-dataset database access (`db[:assets]`, `db[:files]`,
`db[:asset_attachments]`) with a Sequel model layer. The motivation is all of:
associations, validations and clearer error handling, a real domain-object
layer, and timestamp automation.

As part of this, rename the `files` concept to `uploads` everywhere — table,
foreign key, URL route, and on-disk directory.

## Data layer

A single migration, `db/migrate/006_rename_files_to_uploads.rb`:

```ruby
Sequel.migration do
  change do
    rename_table :files, :uploads
    rename_column :asset_attachments, :file_id, :upload_id
  end
end
```

`asset_attachments` has a composite primary key `[asset_id, file_id]` and a
foreign key on `file_id`, so SQLite rebuilds that table during the column
rename. Verify the rebuilt table keeps the composite PK and the FK pointing at
the renamed `uploads`. `change` reverses both operations, so rollback works.

The disk and URL rename lives in code, not the migration (migrations must not
touch the filesystem):

- `App#files_root` becomes `uploads_root` = `storage_path / "uploads"`.
  `file_path` keeps its shape.
- The `web.rb` static-plugin route `/files/` becomes `/uploads/`, and the
  `asset.rb` view image `src` becomes `/uploads/#{id}#{extension}`.

Existing dev blobs in `storage/files/` need to move to `storage/uploads/`.
There is no `db:reset` task and seeds regenerate from the XDG cache, so the
clean path is: delete `db/domus.db` and `storage/`, then
`rake db:migrate db:seed`.

The `documents` table and `Document` model stay as-is — still unused by app
code, now actually required so the model loads.

## Models

All three models live in `lib/domus/models.rb`, with `sole` loaded globally:

```ruby
Sequel::Model.plugin :sole

module Domus
  class Asset < Sequel::Model
    plugin :timestamps
    plugin :validation_helpers
    many_to_many :uploads,
      join_table: :asset_attachments,
      left_key: :asset_id, right_key: :upload_id,
      order: Sequel[:asset_attachments][:created_at]

    def validate
      super
      validates_presence :name
    end
  end

  class Upload < Sequel::Model(:uploads)
    IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp .heic .heif].freeze

    plugin :timestamps
    plugin :validation_helpers
    many_to_many :assets,
      join_table: :asset_attachments,
      left_key: :upload_id, right_key: :asset_id

    def validate
      super
      validates_presence :extension
      validates_includes IMAGE_EXTENSIONS, :extension
    end
  end

  class Document < Sequel::Model
    plugin :timestamps
  end
end
```

Notes:

- `IMAGE_EXTENSIONS` moves from `Web` to `Upload`, so the dependency points
  web → models (correct direction), not the reverse.
- The `timestamps` plugin sets `created_at` on insert. It defaults to also
  setting `updated_at`, which these tables lack. Confirm against Sequel 5.104
  that it tolerates the missing column; if not, pass `update_on_create: false`
  or fall back to a `before_create` hook.
- `Upload` reflects on the `uploads` table at class-load time, so models must
  be required only after migrations have run.

## Routes, seeds, and error handling

`web.rb` references `Upload::IMAGE_EXTENSIONS` and the routes shed datasets:

```ruby
# GET /
assets = Asset.order(Sequel.desc(:created_at), Sequel.desc(:id)).limit(12).all
Views::Home.new(assets:, total: Asset.count).call

# GET /assets/:id
asset = Asset.where(id:).sole          # 0 rows -> NoMatchingRow -> 404
Views::Asset.new(asset:, images: asset.uploads).call
```

`asset.uploads` returns `Upload` models ordered by the join's `created_at`,
replacing the hand-written `asset_images` join method, which is removed. Views
read `upload[:id]` / `upload[:extension]`; `[]` access works on a model, so the
views need no change beyond the `/uploads/` src.

`save_file` becomes model writes inside the existing transaction:

```ruby
db.transaction do
  upload = Upload.create(extension: ext)   # timestamps sets created_at
  dest = app.file_path(id: upload.id, extension: ext)
  FileUtils.mkdir_p(::File.dirname(dest))
  FileUtils.cp(upload[:tempfile].path, dest)
  asset_names.each { |name| Asset.create(name:).add_upload(upload) }
end
```

The MIME-type and size guards stay as `ClientError` raises — they act on the
upload tempfile, not model columns, and need explicit HTTP-status control. The
model presence/extension validations raise `Sequel::ValidationFailed`, mapped
to **422** in the `error_handler` alongside the existing
`Sequel::NoMatchingRow → 404`.

Seeds change the same way: `Asset.create` / `Upload.create` / `add_upload`
replace the three `db[:table].insert` calls, keeping the cache-warming and
transaction structure.

## sole as a model plugin

`lib/sequel/extensions/sole.rb` becomes `lib/sequel/plugins/sole.rb`:

```ruby
module Sequel
  module Plugins
    module Sole
      class TooManyRows < Sequel::Error; end

      module DatasetMethods
        def sole
          results = limit(2).all
          raise Sequel::NoMatchingRow.new(self) if results.empty?
          raise TooManyRows, "expected 1 row, got multiple" if results.length > 1
          results.first
        end
      end
    end
    register_plugin(:sole, Sole)
  end
end
```

- The exception moves from `Sequel::Sole::TooManyRows` to
  `Sequel::Plugins::Sole::TooManyRows`; the error_handler and tests update.
- `app.rb` drops `@db.extension(:sole)`; `models.rb` adds the global
  `Sequel::Model.plugin :sole`.
- On a model dataset, `sole` returns a model instance. The GET /assets/:id
  route uses `Asset.where(id:).sole`, keeping a live caller and identical 404
  semantics.

## Testing

- Require order: models load only after migrations run, in `test_helper.rb`,
  `config.ru`, and the `Rakefile`.
- `test_app.rb`: setup deletes the join table raw (`db[:asset_attachments]
  .delete`) for FK order, then `Asset.dataset.delete` / `Upload.dataset
  .delete`; assertions use `Asset.count`, `Asset.first`, `asset.uploads`.
- `test_sole.rb`: rewritten against `Asset` and
  `Sequel::Plugins::Sole::TooManyRows`.
- New coverage: validations reject blank name / blank or non-image extension
  (`Sequel::ValidationFailed`); the error_handler maps `ValidationFailed` to
  422; `asset.uploads` returns uploads oldest-first.
- `rbs-inline` annotations on the view initializers move from
  `Array[Hash[Symbol, untyped]]` to `Array[Asset]` / `Array[Upload]`; `rake
  check` (rbs-inline + steep) stays green.

## Follow-up

The `sequel` skill (`.claude/skills/sequel/SKILL.md`) references stale paths and
describes models as bare; update it after this lands (task `sqr`).
