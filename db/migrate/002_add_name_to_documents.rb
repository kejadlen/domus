# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:documents) do
      add_column :name, String
    end
  end
end
