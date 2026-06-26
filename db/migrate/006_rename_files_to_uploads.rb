Sequel.migration do
  change do
    rename_table :files, :uploads
    rename_column :asset_attachments, :file_id, :upload_id
  end
end
