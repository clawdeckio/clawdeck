# frozen_string_literal: true

# json gem 2.6+ warns when UTF-8 bytes are tagged as ASCII-8BIT (BINARY) during JSON.generate.
# In json 3.0 this becomes an EncodingError.
#
# We defensively coerce *string values* to UTF-8 when they're marked as BINARY.
# This is intentionally shallow-risk: we only touch Strings, and only when they're ASCII-8BIT.
#
# If we ever need to preserve raw binary blobs, they should be base64-encoded explicitly before
# they reach JSON serialization.

module JsonEncodingGuard
  def generate(obj, *args)
    super(scrub_ascii_8bit(obj), *args)
  end

  private

  def scrub_ascii_8bit(value)
    case value
    when String
      return value if value.encoding == Encoding::UTF_8
      return value unless value.encoding == Encoding::ASCII_8BIT

      # These strings are almost always UTF-8 bytes coming from headers or external sources.
      value.dup.force_encoding(Encoding::UTF_8)
    when Array
      value.map { |v| scrub_ascii_8bit(v) }
    when Hash
      value.each_with_object({}) do |(k, v), acc|
        key = k.is_a?(String) ? scrub_ascii_8bit(k) : k
        acc[key] = scrub_ascii_8bit(v)
      end
    else
      value
    end
  end
end

# Patch JSON.generate globally (used by ActiveSupport::JSON under the hood in many places).
JSON.singleton_class.prepend(JsonEncodingGuard)
