# rbs_inline: enabled

require "roda"
require "fileutils"
require_relative "views/layout"
require_relative "views/home"
require_relative "views/asset"

module Domus
  # Raised when a request can't be processed because of client input. The
  # error_handler plugin renders it with the HTTP status it carries.
  class ClientError < StandardError
    attr_reader :status

    # : (String message, ?status: Integer) -> void
    def initialize(message, status: 422)
      super(message)
      @status = status
    end
  end

  class Web < Roda
    plugin :public
    plugin :all_verbs
    plugin :error_handler do |e|
      raise e unless e.is_a?(ClientError)

      response.status = e.status
      e.message
    end

    IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp .heic .heif].freeze
    MAX_UPLOAD_BYTES = 25 * 1024 * 1024

    route do |r|
      r.public

      r.root do
        r.get do
          assets = db[:assets].order(Sequel.desc(:created_at), Sequel.desc(:id)).limit(12).all
          Views::Home.new(assets:, total: db[:assets].count).call
        end
      end

      # POST /files has no CSRF token check. Domus authenticates via the
      # reverse proxy's trusted X-Forwarded-User header (see
      # lib/middleware/auth.rb), not cookie sessions, so there's no ambient
      # credential a forged cross-site POST could ride on. If this app ever
      # adopts cookie-based sessions, load the Roda :route_csrf plugin and
      # verify the token here before accepting the upload.
      r.on "files" do
        r.post do
          save_file(r.params)
          r.redirect "/"
        end
      end

      r.on "assets" do
        r.is Integer do |id|
          r.get do
            asset = db[:assets].first(id:)
            raise ClientError.new("Asset not found.", status: 404) unless asset

            Views::Asset.new(asset:).call
          end
        end
      end
    end

    private

    # : () -> App
    def app = opts.fetch(:app)
    # : () -> Sequel::Database
    def db = app.db

    # Persists an uploaded image, raising ClientError when the upload is
    # rejected so the error_handler plugin can render the right status.
    # : (Hash[String, untyped]) -> void
    def save_file(params)
      upload = params["file"]
      raise ClientError, "Choose a file to upload." unless upload.is_a?(Hash) && upload[:tempfile]
      raise ClientError, "Only image files are accepted." unless upload[:type].to_s.start_with?("image/")

      # The browser-supplied type is spoofable, so also require a known
      # image extension before we trust and store the file.
      ext = ::File.extname(upload[:filename].to_s).downcase
      raise ClientError, "That image format isn't supported." unless IMAGE_EXTENSIONS.include?(ext)
      raise ClientError, "That image is too large (25 MB max)." if upload[:tempfile].size > MAX_UPLOAD_BYTES

      asset_names = Array(params["asset_names"]).flatten.map(&:strip).reject(&:empty?)

      db.transaction do
        file_id = db[:files].insert(extension: ext, created_at: Time.now)

        dest = app.file_path(id: file_id, extension: ext)
        FileUtils.mkdir_p(::File.dirname(dest))
        FileUtils.cp(upload[:tempfile].path, dest)

        now = Time.now
        asset_names.each do |name|
          asset_id = db[:assets].insert(name: name, created_at: now)
          db[:asset_attachments].insert(asset_id: asset_id, file_id: file_id, created_at: now)
        end
      end
    end
  end
end
