require "test_helper"

class SortableInsertMarkerAssetsTest < ActiveSupport::TestCase
  test "sortable insert marker classes exist in both JS controller and CSS" do
    js = File.read(Rails.root.join("app/javascript/controllers/sortable_controller.js"))
    css = File.read(Rails.root.join("app/assets/stylesheets/application.css"))

    assert_includes js, "sortable-insert-before"
    assert_includes js, "sortable-insert-after"

    assert_includes css, ".sortable-insert-before"
    assert_includes css, ".sortable-insert-after"
  end
end
