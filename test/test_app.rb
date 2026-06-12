# frozen_string_literal: true

require_relative "test_helper"
require "rack/test"
require "tempfile"

class TestApp < Minitest::Test
  include Rack::Test::Methods

  def app
    Domus::Web
  end

  def domus = Domus::Web.opts.fetch(:app)

  def setup
    domus.db[:asset_attachments].delete
    domus.db[:assets].delete
    domus.db[:files].delete
  end

  def test_root
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Domus"
    assert_includes last_response.body, "Add an image"
  end

  def test_upload_image_saves_file_and_redirects
    post "/files", "file" => upload("photo.png", "image/png", "fake-png-bytes")

    assert_equal 302, last_response.status
    rows = domus.db[:files].all
    assert_equal 1, rows.size
    assert_equal ".png", rows.first[:extension]
    assert_equal "fake-png-bytes", File.read(domus.file_path(rows.first))
  end

  def test_upload_without_file_is_rejected
    post "/files", {}

    assert_equal 422, last_response.status
    assert_equal 0, domus.db[:files].count
  end

  def test_upload_rejects_non_image
    post "/files", "file" => upload("notes.txt", "text/plain", "hello")

    assert_equal 422, last_response.status
    assert_equal 0, domus.db[:files].count
  end

  def test_upload_rejects_unsupported_extension
    post "/files", "file" => upload("sketch.svg", "image/svg+xml", "<svg/>")

    assert_equal 422, last_response.status
    assert_equal 0, domus.db[:files].count
  end

  def test_upload_rejects_oversized_file
    oversized = "x" * (Domus::Web::MAX_UPLOAD_BYTES + 1)
    post "/files", "file" => upload("huge.png", "image/png", oversized)

    assert_equal 422, last_response.status
    assert_equal 0, domus.db[:files].count
  end

  def test_upload_with_asset_name_creates_asset_and_attachment
    post "/files", "file" => upload("photo.png", "image/png", "bytes"), "asset_names[]" => "Laptop"

    assert_equal 302, last_response.status
    asset = domus.db[:assets].first
    refute_nil asset
    assert_equal "Laptop", asset[:name]
    file = domus.db[:files].first
    attachment = domus.db[:asset_attachments].first
    refute_nil attachment
    assert_equal asset[:id], attachment[:asset_id]
    assert_equal file[:id], attachment[:file_id]
  end

  def test_upload_with_multiple_asset_names_creates_all
    post "/files", "file" => upload("photo.png", "image/png", "bytes"),
      "asset_names[]" => ["Camera", "Laptop"]

    assert_equal 302, last_response.status
    assert_equal 2, domus.db[:assets].count
    assert_equal 2, domus.db[:asset_attachments].count
  end

  def test_upload_with_blank_asset_names_ignored
    post "/files", "file" => upload("photo.png", "image/png", "bytes"),
      "asset_names[]" => ["", "  "]

    assert_equal 302, last_response.status
    assert_equal 0, domus.db[:assets].count
    assert_equal 0, domus.db[:asset_attachments].count
  end

  def test_upload_without_asset_names_creates_no_assets
    post "/files", "file" => upload("photo.png", "image/png", "bytes")

    assert_equal 302, last_response.status
    assert_equal 0, domus.db[:assets].count
    assert_equal 0, domus.db[:asset_attachments].count
  end

  private

  def upload(filename, type, contents)
    file = Tempfile.new(filename)
    file.binmode
    file.write(contents)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, type, original_filename: filename)
  end
end
