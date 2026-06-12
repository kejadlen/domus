# frozen_string_literal: true

module Domus
  class FileRecord < Sequel::Model(:files)
    def storage_path(config) = ::File.join(config.storage_path, "files", "#{id}#{extension}")
  end
end
