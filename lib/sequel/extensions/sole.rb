require "sequel"

module Sequel
  # The sole extension adds a +sole+ dataset method that returns the single
  # matching row, raising if zero or more than one row matches. It mirrors the
  # ketchup plugin of the same name, but as a dataset extension so it works on
  # Domus's raw datasets without a Sequel::Model layer.
  #
  #   db[:assets].where(id: 1).sole  # => {id: 1, ...}
  #   db[:assets].where(id: 0).sole  # raises Sequel::NoMatchingRow
  #   db[:assets].sole               # raises Sequel::Sole::TooManyRows (if > 1)
  #
  # Load it onto every dataset of a database with:
  #
  #   db.extension(:sole)
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

  Dataset.register_extension(:sole, Sole::DatasetMethods)
end
