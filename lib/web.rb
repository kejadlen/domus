# frozen_string_literal: true

require "roda"
require "fileutils"
require_relative "views/layout"
require_relative "views/capture"

module Domus
  class Web < Roda
    plugin :public
    plugin :all_verbs

    route do |r|
      r.public

      r.root do
        r.get do
          Views::Capture.new.call
        end

        r.post do
          save_file(r.params)
          r.redirect "/"
        end
      end

      r.on "files" do
        r.post do
          save_file(r.params)
          r.redirect "/"
        end
      end
    end

    private

    def db = opts[:db] || opts[:app].db
    def storage_path = opts.fetch(:app).config.storage_path

    def save_file(params)
      upload = params["file"]
      raise ArgumentError, "missing file upload" unless upload.is_a?(Hash) && upload[:tempfile]
      raise ArgumentError, "only images are accepted" unless upload[:type].to_s.start_with?("image/")

      ext = ::File.extname(upload[:filename].to_s)
      now = Time.now
      id = db[:files].insert(
        extension: ext,
        received_at: now,
        created_at: now
      )

      dest_dir = ::File.join(storage_path, "files")
      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp(upload[:tempfile].path, ::File.join(dest_dir, "#{id}#{ext}"))
    end
  end
end
