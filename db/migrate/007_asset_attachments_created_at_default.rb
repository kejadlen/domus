Sequel.migration do
  # The many_to_many association's add_upload inserts into the join table
  # without setting created_at. Give the column a default so the bare insert
  # still populates it and the NOT NULL constraint holds. The timestamp orders
  # an asset's photos (oldest first); upload_id breaks ties within the
  # one-second resolution of CURRENT_TIMESTAMP.
  #
  # set_column_default is irreversible under `change`, so up/down are explicit.
  up do
    alter_table(:asset_attachments) do
      set_column_default :created_at, Sequel::CURRENT_TIMESTAMP
    end
  end

  down do
    alter_table(:asset_attachments) do
      set_column_default :created_at, nil
    end
  end
end
