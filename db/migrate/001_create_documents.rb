# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:documents) do
      primary_key :id
      String :path, null: false
      String :kind, null: false
      DateTime :received_at, null: false
      DateTime :created_at, null: false
    end
  end
end
