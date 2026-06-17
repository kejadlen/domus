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

  def test_root_renders_home
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Domus"
    assert_includes last_response.body, "Recent assets"
  end

  def test_root_lists_recent_assets_newest_first
    now = Time.now
    domus.db[:assets].insert(name: "Older asset", created_at: now - 86_400)
    domus.db[:assets].insert(name: "Newer asset", created_at: now)

    get "/"
    assert_equal 200, last_response.status
    body = last_response.body
    assert_includes body, "Older asset"
    assert_includes body, "Newer asset"
    assert_operator body.index("Newer asset"), :<, body.index("Older asset")
  end

  def test_root_empty_state
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Nothing tracked yet."
  end

  def test_root_capture_actions_open_picker_in_place
    get "/"
    body = last_response.body
    # The capture flow is embedded, so the split button opens the picker in
    # place (primary + alternate) rather than navigating away.
    assert_includes body, "captureApp()"
    assert_includes body, "capturePrimary()"
    assert_includes body, "captureAlternate()"
    refute_includes body, 'href="/capture"'
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
