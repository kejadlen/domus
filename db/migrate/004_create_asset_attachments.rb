# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:asset_attachments) do
      primary_key :id
      foreign_key :asset_id, :assets, null: false
      foreign_key :file_id, :files, null: false
      DateTime :created_at, null: false
    end
  end
end
