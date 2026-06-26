require_relative "test_helper"

class TestSole < Minitest::Test
  include Domus

  def test_sole_returns_the_single_matching_row
    asset = Asset.create(name: "Only")
    assert_equal "Only", Asset.where(id: asset.id).sole.name
  end

  def test_sole_raises_when_no_rows_match
    assert_raises(Sequel::NoMatchingRow) do
      Asset.where(id: 999_999).sole
    end
  end

  def test_sole_raises_when_multiple_rows_match
    Asset.create(name: "A")
    Asset.create(name: "B")

    assert_raises(Sequel::Plugins::Sole::TooManyRows) { Asset.dataset.sole }
  end
end
