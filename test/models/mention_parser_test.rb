require "test_helper"

class MentionParserTest < ActiveSupport::TestCase
  test "extracts handles with punctuation and de-duplicates case-insensitively" do
    text = "Ping @Machamp, @machamp, and @Blastoise."

    assert_equal [ "machamp", "blastoise" ], MentionParser.extract_handles(text)
  end

  test "extract_agent_ids resolves identifier first and then name" do
    ids = MentionParser.extract_agent_ids(
      text: "Ping @machamp and @Blastoise",
      agents_scope: users(:one).agents
    )

    assert_equal [ agents(:one).id, agents(:two).id ].sort, ids.sort
  end

  test "ignores email and url mentions" do
    text = "Email a@b.com and browse http://x.com/@machamp but ping @Machamp."

    assert_equal [ "machamp" ], MentionParser.extract_handles(text)
  end

  test "highlight_mentions only highlights resolved mentions when scope is provided" do
    html = MentionParser.highlight_mentions(
      "Hi @machamp, @Unknown <script>alert(1)</script>",
      agents_scope: users(:one).agents
    )

    assert_includes html, %(<span class="mention">@machamp</span>,)
    assert_not_includes html, %(<span class="mention">@Unknown</span>)
    assert_includes html, "&lt;script&gt;alert(1)&lt;/script&gt;"
    assert_not_includes html, "<script>"
  end

  test "highlight_mentions does not highlight when scope is omitted" do
    html = MentionParser.highlight_mentions("Hi @machamp <script>alert(1)</script>")

    assert_not_includes html, %(<span class="mention">@machamp</span>)
    assert_includes html, "@machamp"
    assert_includes html, "&lt;script&gt;alert(1)&lt;/script&gt;"
  end
end
