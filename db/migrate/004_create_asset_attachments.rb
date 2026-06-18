Sequel.migration do
  change do
    create_table(:asset_attachments) do
      foreign_key :asset_id, :assets, null: false
      foreign_key :file_id, :files, null: false
      DateTime :created_at, null: false
      primary_key [:asset_id, :file_id]
    end
  end
end
