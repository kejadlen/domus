require "sequel"

module Sequel
  module Plugins
    module Sole
      class TooManyRows < Sequel::Error; end

      module DatasetMethods
        def sole
          results = limit(2).all
          raise Sequel::NoMatchingRow.new(self) if results.empty?
          raise TooManyRows, "expected 1 row, got multiple" if results.length > 1

          results.first
        end
      end
    end
  end
end
