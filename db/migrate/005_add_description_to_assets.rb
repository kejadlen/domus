Sequel.migration do
  change do
    alter_table(:assets) do
      add_column :description, String, text: true
    end
  end
end
