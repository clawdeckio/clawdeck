require "test_helper"

class MentionParserTest < ActiveSupport::TestCase
  test "extracts supported agent names uniquely and case-insensitively" do
    text = "Ping @machamp and @Blastoise, then @MACHAMP again."

    assert_equal [ "Machamp", "Blastoise" ], MentionParser.extract_agent_names(text)
  end

  test "ignores unsupported handles" do
    text = "Ping @Pikachu and @Machamp."

    assert_equal [ "Machamp" ], MentionParser.extract_agent_names(text)
  end

  test "highlights supported mentions and escapes unsafe html" do
    html = MentionParser.highlight_mentions("Hi @Machamp <script>alert(1)</script>")

    assert_includes html, %(<span class="mention">@Machamp</span>)
    assert_includes html, "&lt;script&gt;alert(1)&lt;/script&gt;"
    assert_not_includes html, "<script>"
  end
end
