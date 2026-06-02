# frozen_string_literal: true

module Domus
  class Document < Sequel::Model
    one_to_many :email_attachments, key: :email_id, class: :EmailAttachment
  end

  class EmailAttachment < Sequel::Model
    many_to_one :email, class: :Document, key: :email_id
    many_to_one :document, class: :Document, key: :document_id
  end
end
