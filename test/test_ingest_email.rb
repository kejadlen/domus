# frozen_string_literal: true

require_relative "test_helper"
require "rack/test"
require "tempfile"
require "fileutils"
require "sequel"
require_relative "../lib/ingest_email"
require_relative "../lib/config"

class TestIngestEmail < Minitest::Test
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
    post "/inbound/email", {}, {"REMOTE_ADDR" => "167.89.115.100"}
    assert_equal 400, last_response.status
  end

  def test_accepts_email_without_attachments
    post "/inbound/email", {email: sample_email}, {"REMOTE_ADDR" => "167.89.115.100"}
    assert_equal 200, last_response.status

    email_doc = @app.db[:documents].where(kind: "email").first
    refute_nil email_doc
    assert_match %r{emails/\d{4}-\d{2}-\d{2}-.+\.eml}, email_doc[:path]
  end

  def test_stores_eml_file
    post "/inbound/email", {email: sample_email}, {"REMOTE_ADDR" => "167.89.115.100"}
    assert_equal 200, last_response.status

    email_doc = @app.db[:documents].where(kind: "email").first
    full_path = File.join(@test_storage, email_doc[:path])
    assert File.exist?(full_path)
    assert_equal sample_email, File.read(full_path)
  end

  def test_stores_pdf_attachment
    post "/inbound/email",
      {email: sample_email,
      attachment1: attachment_param("report.pdf", "application/pdf", "pdf content")},
      {"REMOTE_ADDR" => "167.89.115.100"}

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
      {email: sample_email,
      attachment1: attachment_param("a.txt", "text/plain", "aaa"),
      attachment2: attachment_param("b.txt", "text/plain", "bbb")},
      {"REMOTE_ADDR" => "167.89.115.100"}

    assert_equal 200, last_response.status
    assert_equal 2, @app.db[:email_attachments].count
    assert_equal 3, @app.db[:documents].count
  end

  def test_attachment_linked_to_correct_email
    post "/inbound/email",
      {email: sample_email,
      attachment1: attachment_param("doc.pdf", "application/pdf", "data")},
      {"REMOTE_ADDR" => "167.89.115.100"}

    email_doc = @app.db[:documents].where(kind: "email").first
    ea = @app.db[:email_attachments].first
    assert_equal email_doc[:id], ea[:email_id]
  end

  def test_pdf_attachment_has_correct_kind
    post "/inbound/email",
      {email: sample_email,
      attachment1: attachment_param("file.pdf", "application/pdf", "data")},
      {"REMOTE_ADDR" => "167.89.115.100"}

    ea = @app.db[:email_attachments].first
    doc = @app.db[:documents].where(id: ea[:document_id]).first
    assert_equal "pdf", doc[:kind]
  end

  def test_attachment_path_includes_random_uuid
    post "/inbound/email",
      {email: sample_email,
      attachment1: attachment_param("file.pdf", "application/pdf", "data")},
      {"REMOTE_ADDR" => "167.89.115.100"}

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
    Rack::Test::UploadedFile.new(tempfile.path, type, original_filename: filename)
  end
end
