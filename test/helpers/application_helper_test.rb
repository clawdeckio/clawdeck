require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "formatted_timestamp returns stable format with timezone" do
    time = Time.zone.parse("2026-02-07 04:23:00")
    formatted = formatted_timestamp(time)

    assert_match(/\A2026-02-07 04:23 /, formatted)
    # Should include a timezone suffix (e.g., PST/PDT/UTC)
    assert_match(/\b[A-Z]{2,4}\z/, formatted)
  end

  test "formatted_timestamp handles nil" do
    assert_equal "", formatted_timestamp(nil)
  end

  test "compact_relative_time returns compact labels for past timestamps" do
    now = Time.zone.parse("2026-02-08 12:00:00")

    assert_equal "2h ago", compact_relative_time(now - 2.hours, now: now)
    assert_equal "3d ago", compact_relative_time(now - 3.days, now: now)
  end

  test "compact_relative_time handles nil" do
    assert_equal "", compact_relative_time(nil)
  end
end
