# frozen_string_literal: true

require_relative "test_helper"
require_relative "../lib/relative_time"

class TestRelativeTime < Minitest::Test
  def fmt(seconds_ago)
    now = Time.now
    Domus::RelativeTime.format(now - seconds_ago, now: now)
  end

  def test_blank_for_nil
    assert_equal "", Domus::RelativeTime.format(nil)
  end

  def test_now_under_a_minute
    assert_equal "now", fmt(30)
  end

  def test_minutes
    assert_equal "5m", fmt(5 * 60)
  end

  def test_hours
    assert_equal "3h", fmt(3 * 60 * 60)
  end

  def test_days
    assert_equal "2d", fmt(2 * 86_400)
  end

  def test_weeks
    assert_equal "1w", fmt(8 * 86_400)
  end

  def test_months
    assert_equal "2mo", fmt(70 * 86_400)
  end

  def test_years
    assert_equal "1y", fmt(400 * 86_400)
  end
end
