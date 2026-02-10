require "minitest/autorun"
require "json"
require_relative "../../config/initializers/json_encoding_guard"

class JsonEncodingGuardTest < Minitest::Test
  JSON_ENTRYPOINTS = %i[generate fast_generate pretty_generate dump].freeze

  def test_json_entrypoints_coerce_ascii_8bit_string_values_to_utf_8
    expected = "Pok\u00E9mon"

    JSON_ENTRYPOINTS.each do |entrypoint|
      binary_value = expected.dup.force_encoding(Encoding::ASCII_8BIT)
      payload = { "name" => binary_value }

      json = nil
      _, stderr = capture_io do
        json = JSON.public_send(entrypoint, payload)
      end

      refute_match(
        /UTF-8 string passed as BINARY/,
        stderr,
        "expected JSON.#{entrypoint} to avoid UTF-8/BINARY warnings"
      )
      assert_includes(json, expected)
      assert_equal(expected, JSON.parse(json).fetch("name"))
    end
  end
end
