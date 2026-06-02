# Documents Schema Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the separate `emails`, `pdfs`, `images`, and polymorphic `attachments` tables with a unified `documents` table and a clean `email_attachments` join table.

**Architecture:** Every stored file (email, PDF, image, unknown) is a `documents` row with a `kind` column. The relationship "this document was attached to this email" is modeled as an `email_attachments` row with two foreign keys into `documents`. No polymorphic joins.

**Tech Stack:** Ruby, Sequel, SQLite, Minitest, Rack::Test

---

### Task 1: Rewrite the migration

Since migration 001 is staged but not yet committed, rewrite it in place. The new schema drops the four old tables and creates two.

**Files:**
- Modify: `db/migrate/001_create_emails_and_attachments.rb`

**Step 1: Replace the migration**

```ruby
# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:documents) do
      primary_key :id
      String :path, null: false
      String :kind, null: false  # "email", "pdf", "image", "unknown"
      DateTime :received_at, null: false
      DateTime :created_at, null: false
    end

    create_table(:email_attachments) do
      primary_key :id
      foreign_key :email_id, :documents, null: false
      foreign_key :document_id, :documents, null: false
      String :filename, null: false
      DateTime :created_at, null: false
    end
  end
end
```

**Step 2: Verify it loads without error**

```
bundle exec ruby -e "require 'sequel'; require_relative 'db/migrate/001_create_emails_and_attachments'"
```

Expected: no output, exit 0.

---

### Task 2: Rewrite the ingestion tests

Write tests that target the new schema. They will fail until Task 3 is done.

**Files:**
- Modify: `test/test_email_ingestion.rb`

**Step 1: Replace the test file**

```ruby
# frozen_string_literal: true

require_relative "test_helper"
require "rack/test"
require "tempfile"
require "fileutils"
require "sequel"
require_relative "../lib/email_ingestion"
require_relative "../lib/config"

class TestEmailIngestion < Minitest::Test
  include Rack::Test::Methods

  def app
    Domus::Web
  end

  def setup
    @test_storage = Dir.mktmpdir("domus-email-test")
    @config = Domus::Config.new(database_url: ":memory:", storage_path: @test_storage)
    @app = Domus::App.new(@config)
    Sequel::Migrator.run(@app.db, migrate_dir)

    @old_app = Domus::Web.opts[:app]
    Domus::Web.opts[:app] = @app
  end

  def teardown
    Domus::Web.opts[:app] = @old_app
    FileUtils.rm_rf(@test_storage)
  end

  def test_rejects_missing_email_field
    post "/inbound/email"
    assert_equal 400, last_response.status
  end

  def test_accepts_email_without_attachments
    post "/inbound/email", email: sample_email
    assert_equal 200, last_response.status

    email_doc = @app.db[:documents].where(kind: "email").first
    refute_nil email_doc
    assert_match %r{emails/\d{4}-\d{2}-\d{2}-.+\.eml}, email_doc[:path]
  end

  def test_stores_eml_file
    post "/inbound/email", email: sample_email
    assert_equal 200, last_response.status

    email_doc = @app.db[:documents].where(kind: "email").first
    full_path = File.join(@test_storage, email_doc[:path])
    assert File.exist?(full_path)
    assert_equal sample_email, File.read(full_path)
  end

  def test_stores_pdf_attachment
    post "/inbound/email",
      email: sample_email,
      attachment1: attachment_param("report.pdf", "application/pdf", "pdf content")

    assert_equal 200, last_response.status

    ea = @app.db[:email_attachments].first
    refute_nil ea
    assert_match(/report\.pdf/, ea[:filename])

    email_doc = @app.db[:documents].where(kind: "email").first
    assert_equal email_doc[:id], ea[:email_id]

    att_doc = @app.db[:documents].where(id: ea[:document_id]).first
    full_path = File.join(@test_storage, att_doc[:path])
    assert File.exist?(full_path)
    assert_equal "pdf content", File.read(full_path)
  end

  def test_stores_multiple_attachments
    post "/inbound/email",
      email: sample_email,
      attachment1: attachment_param("a.txt", "text/plain", "aaa"),
      attachment2: attachment_param("b.txt", "text/plain", "bbb")

    assert_equal 200, last_response.status
    assert_equal 2, @app.db[:email_attachments].count
    assert_equal 3, @app.db[:documents].count
  end

  def test_attachment_linked_to_correct_email
    post "/inbound/email",
      email: sample_email,
      attachment1: attachment_param("doc.pdf", "application/pdf", "data")

    email_doc = @app.db[:documents].where(kind: "email").first
    ea = @app.db[:email_attachments].first
    assert_equal email_doc[:id], ea[:email_id]
  end

  def test_pdf_attachment_has_correct_kind
    post "/inbound/email",
      email: sample_email,
      attachment1: attachment_param("file.pdf", "application/pdf", "data")

    ea = @app.db[:email_attachments].first
    doc = @app.db[:documents].where(id: ea[:document_id]).first
    assert_equal "pdf", doc[:kind]
  end

  def test_attachment_path_includes_random_uuid
    post "/inbound/email",
      email: sample_email,
      attachment1: attachment_param("file.pdf", "application/pdf", "data")

    ea = @app.db[:email_attachments].first
    doc = @app.db[:documents].where(id: ea[:document_id]).first
    assert_match %r{pdfs/\d{4}-\d{2}-\d{2}-.+file\.pdf}, doc[:path]
  end

  private

  def migrate_dir
    File.expand_path("../db/migrate", __dir__)
  end

  def sample_email
    "From: sender@example.com\nSubject: Test Subject\n\nBody"
  end

  def attachment_param(filename, type, content)
    tempfile = Tempfile.new(filename)
    tempfile.write(content)
    tempfile.rewind
    Rack::Test::UploadedFile.new(tempfile.path, type)
  end
end
```

**Step 2: Run tests to confirm they fail**

```
bundle exec ruby -Itest test/test_email_ingestion.rb
```

Expected: failures referencing missing `documents` table or wrong column names (since `email_ingestion.rb` still writes to old tables).

---

### Task 3: Rewrite the ingestion processor

Replace the multi-table dispatch with a single `documents` + `email_attachments` write path.

**Files:**
- Modify: `lib/email_ingestion.rb`

**Step 1: Replace the file**

```ruby
# frozen_string_literal: true

require "securerandom"
require "fileutils"

module Domus
  module EmailIngestation
    class Processor
      def initialize(app)
        @app = app
        @config = app.config
        @db = app.db
        @storage = config.storage_path
      end

      def call(email_field:, attachments: [])
        eml_path = nil
        written_files = []

        db.transaction do
          eml_relative = write_eml(email_field)
          eml_path = eml_relative
          written_files << eml_relative

          email_doc_id = db[:documents].insert(
            path: eml_relative,
            kind: "email",
            received_at: Time.now,
            created_at: Time.now
          )

          attachments.each do |att|
            kind = classify(att[:filename])
            content = att[:tempfile].read
            relative = write_file(storage_subdir(kind), att[:filename], content)
            written_files << relative

            doc_id = db[:documents].insert(
              path: relative,
              kind: kind.to_s,
              received_at: Time.now,
              created_at: Time.now
            )

            db[:email_attachments].insert(
              email_id: email_doc_id,
              document_id: doc_id,
              filename: att[:filename],
              created_at: Time.now
            )
          end
        end

        { email_path: eml_path }
      ensure
        written_files.each { |rel| FileUtils.rm_f(File.join(storage, rel)) } if $!
      end

      private

      attr_reader :config, :db

      def classify(filename)
        ext = File.extname(filename).downcase
        return :pdf if ext == ".pdf"
        return :image if %w[.jpg .jpeg .png .gif .webp .bmp .tiff .tif .svg].include?(ext)

        :unknown
      end

      def storage_subdir(kind)
        case kind
        when :pdf then "pdfs"
        when :image then "images"
        else "files"
        end
      end

      def write_eml(content)
        write_file("emails", nil, content)
      end

      def write_file(subdir, original_filename, content)
        relative = File.join(subdir, filename(original_filename))
        full = File.join(storage, relative)
        FileUtils.mkdir_p(File.dirname(full))
        mode = content.encoding == Encoding::ASCII_8BIT ? "wb" : "w"
        File.write(full, content, mode: mode)
        relative
      end

      def filename(original = nil)
        date = Time.now.strftime("%Y-%m-%d")
        uuid = SecureRandom.uuid
        base = "#{date}-#{uuid}"
        return "#{base}.eml" unless original

        "#{base}-#{original}"
      end

      def storage
        @storage
      end
    end

    class << self
      def parse_multipart(request, config, db)
        email_field = request.params["email"]
        attachments = []

        request.params.each do |key, value|
          next unless key.to_s.match?(/^attachment\d+$/)

          att = attachment_from_param(value)
          attachments << att if att
        end

        [email_field, attachments]
      end

      def attachment_from_param(value)
        if value.respond_to?(:tempfile) && value.respond_to?(:original_filename)
          { filename: value.original_filename, tempfile: value }
        elsif value.is_a?(Hash) && value[:tempfile].is_a?(Tempfile)
          { filename: value[:filename], tempfile: value[:tempfile] }
        end
      end

      def handle(roda)
        app = roda.opts[:app]
        email_field, attachments = parse_multipart(roda.request, app.config, app.db)
        unless email_field
          roda.response.status = 400
          roda.response.write "Bad Request: missing email field"
          return
        end

        Processor.new(app).call(email_field: email_field, attachments: attachments)
        roda.response.status = 200
        roda.response.write "OK"
      rescue StandardError => e
        roda.response.status = 500
        roda.response.write "Error: #{e.message}"
      end
    end
  end
end
```

**Step 2: Run the ingestion tests**

```
bundle exec ruby -Itest test/test_email_ingestion.rb
```

Expected: all tests pass.

**Step 3: Run the full test suite**

```
bundle exec rake test
```

Expected: all tests pass including `test_ip_allowlist.rb`.

---

### Task 4: Replace model files

The old stubs (`email.rb`, `pdf.rb`, `image.rb`, `attachment.rb`) are not loaded anywhere. Delete them and add models for the new tables.

**Files:**
- Delete: `lib/models/email.rb`, `lib/models/pdf.rb`, `lib/models/image.rb`, `lib/models/attachment.rb`
- Create: `lib/models/document.rb`, `lib/models/email_attachment.rb`

**Step 1: Delete old model files**

```
rm lib/models/email.rb lib/models/pdf.rb lib/models/image.rb lib/models/attachment.rb
```

**Step 2: Create `lib/models/document.rb`**

```ruby
# frozen_string_literal: true

module Domus
  class Document < Sequel::Model
    one_to_many :outbound_attachments, class: :EmailAttachment, key: :email_id
    one_to_many :inbound_attachments, class: :EmailAttachment, key: :document_id
  end
end
```

**Step 3: Create `lib/models/email_attachment.rb`**

```ruby
# frozen_string_literal: true

module Domus
  class EmailAttachment < Sequel::Model
    many_to_one :email, class: :Document, key: :email_id
    many_to_one :document, class: :Document, key: :document_id
  end
end
```

**Step 4: Run the full test suite again**

```
bundle exec rake test
```

Expected: still all green.

---

### Task 5: Commit

**Step 1: Check what's staged**

```
jj diff --stat
```

**Step 2: Commit**

```
jj commit -m "Unify document storage into documents and email_attachments tables

Replace the separate emails, pdfs, and images tables and the polymorphic
attachments join with a single documents table (kind column) and a clean
email_attachments join. Emails are now first-class documents.

Assisted-by: Claude Sonnet 4.6 <noreply@anthropic.com>"
```
