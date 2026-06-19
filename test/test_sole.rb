require_relative "test_helper"

class TestSole < Minitest::Test
  def db = Domus::Web::APP.db

  def setup
    db[:asset_attachments].delete
    db[:assets].delete
  end

  def test_sole_returns_the_single_matching_row
    id = db[:assets].insert(name: "Only", created_at: Time.now)
    assert_equal "Only", db[:assets].where(id:).sole[:name]
  end

  def test_sole_raises_when_no_rows_match
    assert_raises(Sequel::NoMatchingRow) do
      db[:assets].where(id: 999_999).sole
    end
  end

  def test_sole_raises_when_multiple_rows_match
    db[:assets].insert(name: "A", created_at: Time.now)
    db[:assets].insert(name: "B", created_at: Time.now)

    assert_raises(Sequel::Sole::TooManyRows) { db[:assets].sole }
  end
end
