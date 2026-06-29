# rbs_inline: enabled

require "sequel"
require_relative "db"

Sequel::Model.plugin :sole

module Domus
  class Asset < Sequel::Model
    plugin :timestamps, update_on_create: false
    plugin :validation_helpers
    many_to_many :uploads,
      join_table: :asset_attachments,
      left_key: :asset_id, right_key: :upload_id,
      order: [Sequel[:asset_attachments][:created_at], Sequel[:asset_attachments][:upload_id]]

    def validate
      super
      validates_presence :name
    end
  end

  class Upload < Sequel::Model(:uploads)
    IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp .heic .heif].freeze

    plugin :timestamps, update_on_create: false
    plugin :validation_helpers
    many_to_many :assets,
      join_table: :asset_attachments,
      left_key: :upload_id, right_key: :asset_id

    def validate
      super
      validates_presence :extension
      validates_includes IMAGE_EXTENSIONS, :extension
    end

    # Where this upload's blob lives on disk.
    #: () -> Pathname
    def file_path = Domus.config.uploads_root / "#{id}#{extension}"
  end

  class Document < Sequel::Model
    plugin :timestamps, update_on_create: false
  end
end
