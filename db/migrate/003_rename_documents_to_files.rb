# frozen_string_literal: true

Sequel.migration do
  change do
    rename_table :documents, :files
  end
end
