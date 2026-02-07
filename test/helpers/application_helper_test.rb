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
end
