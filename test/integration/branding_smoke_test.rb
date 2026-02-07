require "test_helper"

class BrandingSmokeTest < ActionDispatch::IntegrationTest
  test "public pages use PokéDeck branding (no ClawDeck remnants)" do
    # Home page
    get root_path
    assert_response :success

    assert_includes @response.body, "PokéDeck"
    assert_not_includes @response.body, "ClawDeck"
    assert_not_includes @response.body, "Claw Deck"

    # PWA manifest (served as JSON via /manifest.json)
    get "/manifest.json"
    assert_response :success

    assert_includes @response.body, "PokéDeck"
    assert_not_includes @response.body, "ClawDeck"
    assert_not_includes @response.body, "Claw Deck"
  end
end
