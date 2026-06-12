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

  def test_root_shows_assets
    domus.db[:assets].insert(name: "Camera", created_at: Time.now)

    get "/"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "Camera"
  end

  def test_upload_with_asset_ids_creates_attachments
    asset_id = domus.db[:assets].insert(name: "Laptop", created_at: Time.now)

    post "/files", "file" => upload("photo.png", "image/png", "bytes"), "asset_ids[]" => asset_id.to_s

    assert_equal 302, last_response.status
    file = domus.db[:files].first
    attachment = domus.db[:asset_attachments].first
    refute_nil attachment
    assert_equal asset_id, attachment[:asset_id]
    assert_equal file[:id], attachment[:file_id]
  end

  def test_upload_with_multiple_asset_ids_creates_all_attachments
    id1 = domus.db[:assets].insert(name: "Camera", created_at: Time.now)
    id2 = domus.db[:assets].insert(name: "Laptop", created_at: Time.now)

    post "/files", "file" => upload("photo.png", "image/png", "bytes"),
      "asset_ids[]" => [id1.to_s, id2.to_s]

    assert_equal 302, last_response.status
    assert_equal 2, domus.db[:asset_attachments].count
  end

  def test_upload_without_asset_ids_creates_no_attachments
    post "/files", "file" => upload("photo.png", "image/png", "bytes")

    assert_equal 302, last_response.status
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
