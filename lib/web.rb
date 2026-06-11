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
          save_document(r.params)
          r.redirect "/"
        end
      end

      r.on "documents" do
        r.post do
          save_document(r.params)
          r.redirect "/"
        end
      end
    end

    private

    def db = opts[:db] || opts[:app].db
    def storage_path = opts.fetch(:app).config.storage_path

    def save_document(params)
      upload = params["file"]
      raise ArgumentError, "missing file upload" unless upload.is_a?(Hash) && upload[:tempfile]

      ext = File.extname(upload[:filename].to_s)
      filename = "#{Time.now.strftime("%Y%m%d%H%M%S%L")}#{ext}"
      dest_dir = File.join(storage_path, "documents")
      FileUtils.mkdir_p(dest_dir)
      dest = File.join(dest_dir, filename)
      FileUtils.cp(upload[:tempfile].path, dest)

      now = Time.now
      db[:documents].insert(
        path: File.join("documents", filename),
        kind: upload[:type].to_s,
        received_at: now,
        created_at: now
      )
    end
  end
end
