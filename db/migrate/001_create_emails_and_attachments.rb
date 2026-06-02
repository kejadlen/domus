# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:documents) do
      primary_key :id
      String :path, null: false
      String :kind, null: false  # "email", "pdf", "image", "unknown"
      DateTime :received_at, null: false
      DateTime :created_at, null: false
    end

    create_table(:email_attachments) do
      primary_key :id
      foreign_key :email_id, :documents, null: false, index: true
      foreign_key :document_id, :documents, null: false, index: true
      String :filename, null: false
      DateTime :created_at, null: false
    end

    run <<~SQL
      CREATE TRIGGER enforce_email_attachment_kind
      BEFORE INSERT ON email_attachments
      BEGIN
        SELECT RAISE(ABORT, 'email_id must reference a document with kind=''email''')
        WHERE (SELECT kind FROM documents WHERE id = NEW.email_id) != 'email';
      END;
    SQL
  end
end
