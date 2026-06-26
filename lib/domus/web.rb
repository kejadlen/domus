# rbs_inline: enabled

require "roda"
require "fileutils"
require_relative "config"
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

    # Serve stored uploads (storage/uploads/{id}{ext}) at /uploads/ straight
    # off disk. The :static plugin needs a concrete root at load time, so it
    # reads the shared Domus.config (the same instance App uses). Uploads are
    # immutable once stored, so they cache indefinitely.
    plugin :static, ["/uploads/"],
      root: Domus.config.storage_path.to_s,
      cache_control: "private, max-age=31536000, immutable"

    plugin :all_verbs
    plugin :error_handler do |e|
      case e
      when ClientError
        response.status = e.status
        e.message
      when Sequel::NoMatchingRow
        response.status = 404
        "Not found."
      when Sequel::ValidationFailed
        response.status = 422
        e.message
      else
        raise e
      end
    end

    MAX_UPLOAD_BYTES = 25 * 1024 * 1024

    route do |r|
      r.public

      r.root do
        r.get do
          assets = Asset.order(Sequel.desc(:created_at), Sequel.desc(:id)).limit(12).all
          Views::Home.new(assets:, total: Asset.count).call
        end
      end

      # POST /uploads has no CSRF token check. Domus authenticates via the
      # reverse proxy's trusted X-Forwarded-User header (see
      # lib/middleware/auth.rb), not cookie sessions, so there's no ambient
      # credential a forged cross-site POST could ride on. If this app ever
      # adopts cookie-based sessions, load the Roda :route_csrf plugin and
      # verify the token here before accepting the upload.
      # GET /uploads/:filename (the stored uploads) is served straight off
      # disk by the :static middleware configured above. POST /uploads stays
      # on the route.
      r.on "uploads" do
        r.post do
          save_file(r.params)
          r.redirect "/"
        end
      end

      r.on "assets" do
        r.is Integer do |id|
          r.get do
            # .sole raises Sequel::NoMatchingRow when the id is unknown; the
            # error_handler above turns that into a 404.
            asset = Asset.where(id:).sole
            Views::Asset.new(asset:, images: asset.uploads).call
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
      raise ClientError, "That image format isn't supported." unless Upload::IMAGE_EXTENSIONS.include?(ext)
      raise ClientError, "That image is too large (25 MB max)." if upload[:tempfile].size > MAX_UPLOAD_BYTES

      asset_names = Array(params["asset_names"]).flatten.map(&:strip).reject(&:empty?)

      db.transaction do
        upload_record = Upload.create(extension: ext)
        dest = app.file_path(id: upload_record.id, extension: ext)
        FileUtils.mkdir_p(::File.dirname(dest))
        FileUtils.cp(upload[:tempfile].path, dest)
        asset_names.each { |name| Asset.create(name:).add_upload(upload_record) }
      end
    end
  end
end
