# frozen_string_literal: true

require "securerandom"
require "fileutils"

module Domus
  class IngestEmail
    def initialize(app)
      @config = app.config
      @db = app.db
      @storage = app.config.storage_path
    end

    def call(email_field:, attachments: [])
      now = Time.now
      eml_path = nil
      written_files = []
      committed = false

      db.transaction do
        eml_path = write_eml(email_field, now)
        written_files << eml_path

        email_doc_id = db[:documents].insert(
          path: eml_path,
          kind: "email",
          received_at: now,
          created_at: now
        )

        attachments.each do |att|
          kind = classify(att[:filename])
          content = att[:tempfile].read
          relative = write_file(storage_subdir(kind), att[:filename], content, now)
          written_files << relative

          doc_id = db[:documents].insert(
            path: relative,
            kind: kind.to_s,
            received_at: now,
            created_at: now
          )

          db[:email_attachments].insert(
            email_id: email_doc_id,
            document_id: doc_id,
            filename: att[:filename],
            created_at: now
          )
        end

        committed = true
      end

      { email_path: eml_path }
    ensure
      written_files.each { |rel| FileUtils.rm_f(File.join(@storage, rel)) } unless committed
    end

    class << self
      def handle(roda)
        app = roda.opts[:app]
        email_field, attachments = parse_multipart(roda.request)
        unless email_field
          roda.response.status = 400
          roda.response.write "Bad Request: missing email field"
          return
        end

        new(app).call(email_field: email_field, attachments: attachments)
        roda.response.status = 200
        roda.response.write "OK"
      rescue StandardError => e
        roda.response.status = 500
        roda.response.write "Error: #{e.message}"
      end

      def parse_multipart(request)
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
    end

    private

    attr_reader :db

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

    def write_eml(content, now)
      write_file("emails", nil, content, now)
    end

    def write_file(subdir, original_filename, content, now)
      relative = File.join(subdir, filename(original_filename, now))
      full = File.join(@storage, relative)
      FileUtils.mkdir_p(File.dirname(full))
      mode = content.encoding == Encoding::ASCII_8BIT ? "wb" : "w"
      File.write(full, content, mode: mode)
      relative
    end

    def filename(original = nil, now = Time.now)
      date = now.strftime("%Y-%m-%d")
      uuid = SecureRandom.uuid
      base = "#{date}-#{uuid}"
      return "#{base}.eml" unless original

      "#{base}-#{File.basename(original)}"
    end
  end
end
