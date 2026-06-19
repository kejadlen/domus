require_relative "test_helper"
require "rack/test"
require "tempfile"

class TestApp < Minitest::Test
  include Rack::Test::Methods

  def app
    Domus::Web
  end

  def domus = Domus::Web.opts[:app]

  # Every test starts from the shared seed baseline, so dev and the suite
  # exercise the same Domus::Seeds path. Tests that need a clean slate call
  # #wipe; tests that assert on counts compare deltas around the action.
  def setup
    wipe
    Domus::Seeds.call(domus)
  end

  def wipe
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
    wipe
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

  def test_root_links_each_asset_to_its_detail_page
    id = domus.db[:assets].insert(name: "Laptop", created_at: Time.now)

    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, %(href="/assets/#{id}")
  end

  def test_root_empty_state
    wipe
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

  def test_asset_detail_renders_title
    id = domus.db[:assets].insert(name: "Bosch 800 dishwasher", created_at: Time.now)

    get "/assets/#{id}"
    assert_equal 200, last_response.status
    body = last_response.body
    assert_includes body, "Bosch 800 dishwasher"
    assert_includes body, "Assets" # breadcrumb back to the index
  end

  def test_asset_detail_renders_description
    id = domus.db[:assets].insert(
      name: "Bosch 800 dishwasher",
      description: "Stainless interior, third rack.\n\nReplaces the GE that flooded.",
      created_at: Time.now
    )

    get "/assets/#{id}"
    assert_equal 200, last_response.status
    body = last_response.body
    assert_includes body, "Stainless interior, third rack."
    assert_includes body, "Replaces the GE that flooded."
  end

  def test_asset_detail_omits_description_when_absent
    id = domus.db[:assets].insert(name: "Untitled", created_at: Time.now)

    get "/assets/#{id}"
    assert_equal 200, last_response.status
    refute_includes last_response.body, 'class="desc"'
  end

  def test_asset_detail_missing_is_404
    get "/assets/999999"
    assert_equal 404, last_response.status
  end

  def test_asset_detail_renders_attached_images
    now = Time.now
    asset_id = domus.db[:assets].insert(name: "Dishwasher", created_at: now)
    file_id = domus.db[:files].insert(extension: ".png", created_at: now)
    domus.db[:asset_attachments].insert(asset_id:, file_id:, created_at: now)

    get "/assets/#{asset_id}"
    assert_equal 200, last_response.status
    assert_includes last_response.body, %(src="/files/#{file_id}.png")
  end

  def test_asset_detail_without_images_shows_photos_add_affordance
    id = domus.db[:assets].insert(name: "Bare", created_at: Time.now)

    get "/assets/#{id}"
    assert_equal 200, last_response.status
    # The photos section always renders (with the add affordance); there
    # just aren't any <img> tiles when nothing is attached.
    assert_includes last_response.body, "addphoto"
    refute_includes last_response.body, "<img"
  end

  def test_get_file_serves_stored_image
    post "/files", "file" => upload("photo.png", "image/png", "fake-png-bytes")
    file = domus.db[:files].order(:id).last

    get "/files/#{file[:id]}#{file[:extension]}"
    assert_equal 200, last_response.status
    assert_equal "image/png", last_response.headers["Content-Type"]
    assert_includes last_response.headers["Cache-Control"].to_s, "immutable"
    assert_equal "fake-png-bytes", last_response.body
  end

  def test_get_missing_file_is_404
    get "/files/999999.png"
    assert_equal 404, last_response.status
  end

  def test_upload_image_saves_file_and_redirects
    before = domus.db[:files].count
    post "/files", "file" => upload("photo.png", "image/png", "fake-png-bytes")

    assert_equal 302, last_response.status
    assert_equal before + 1, domus.db[:files].count
    row = domus.db[:files].order(:id).last
    assert_equal ".png", row[:extension]
    assert_equal "fake-png-bytes", File.read(domus.file_path(row))
  end

  def test_upload_without_file_is_rejected
    before = domus.db[:files].count
    post "/files", {}

    assert_equal 422, last_response.status
    assert_equal before, domus.db[:files].count
  end

  def test_upload_rejects_non_image
    before = domus.db[:files].count
    post "/files", "file" => upload("notes.txt", "text/plain", "hello")

    assert_equal 422, last_response.status
    assert_equal before, domus.db[:files].count
  end

  def test_upload_rejects_unsupported_extension
    before = domus.db[:files].count
    post "/files", "file" => upload("sketch.svg", "image/svg+xml", "<svg/>")

    assert_equal 422, last_response.status
    assert_equal before, domus.db[:files].count
  end

  def test_upload_rejects_oversized_file
    before = domus.db[:files].count
    oversized = "x" * (Domus::Web::MAX_UPLOAD_BYTES + 1)
    post "/files", "file" => upload("huge.png", "image/png", oversized)

    assert_equal 422, last_response.status
    assert_equal before, domus.db[:files].count
  end

  def test_upload_with_asset_name_creates_asset_and_attachment
    before = domus.db[:assets].count
    post "/files", "file" => upload("photo.png", "image/png", "bytes"), "asset_names[]" => "Laptop"

    assert_equal 302, last_response.status
    assert_equal before + 1, domus.db[:assets].count
    asset = domus.db[:assets].order(:id).last
    assert_equal "Laptop", asset[:name]
    file = domus.db[:files].order(:id).last
    attachment = domus.db[:asset_attachments].where(asset_id: asset[:id]).first
    refute_nil attachment
    assert_equal file[:id], attachment[:file_id]
  end

  def test_upload_with_multiple_asset_names_creates_all
    assets_before = domus.db[:assets].count
    attachments_before = domus.db[:asset_attachments].count
    post "/files", "file" => upload("photo.png", "image/png", "bytes"),
      "asset_names[]" => ["Camera", "Laptop"]

    assert_equal 302, last_response.status
    assert_equal assets_before + 2, domus.db[:assets].count
    assert_equal attachments_before + 2, domus.db[:asset_attachments].count
  end

  def test_upload_with_blank_asset_names_ignored
    assets_before = domus.db[:assets].count
    attachments_before = domus.db[:asset_attachments].count
    post "/files", "file" => upload("photo.png", "image/png", "bytes"),
      "asset_names[]" => ["", "  "]

    assert_equal 302, last_response.status
    assert_equal assets_before, domus.db[:assets].count
    assert_equal attachments_before, domus.db[:asset_attachments].count
  end

  def test_upload_without_asset_names_creates_no_assets
    assets_before = domus.db[:assets].count
    attachments_before = domus.db[:asset_attachments].count
    post "/files", "file" => upload("photo.png", "image/png", "bytes")

    assert_equal 302, last_response.status
    assert_equal assets_before, domus.db[:assets].count
    assert_equal attachments_before, domus.db[:asset_attachments].count
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
