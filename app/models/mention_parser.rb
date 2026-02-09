class MentionParser
  SUPPORTED_AGENT_NAMES = %w[Machamp Blastoise Alakazam Snorlax].freeze
  MENTION_PATTERN = /
    (?<![A-Za-z0-9_])                  # no word char before @
    @(?<agent>#{SUPPORTED_AGENT_NAMES.join("|")})
    (?![A-Za-z0-9_])                   # no word char after handle
  /ix.freeze

  class << self
    def extract_agent_names(text)
      return [] if text.blank?

      text.to_s
        .scan(MENTION_PATTERN)
        .flatten
        .filter_map { |name| canonical_name(name) }
        .uniq
    end

    def extract_agent_ids(text:, agents_scope:)
      names = extract_agent_names(text)
      return [] if names.empty?

      agents_scope
        .where("LOWER(name) IN (?)", names.map(&:downcase))
        .pluck(:id)
        .uniq
    end

    # Escape raw user text and only inject markup for known @mentions.
    def highlight_mentions(text)
      escaped = ERB::Util.html_escape(text.to_s)

      escaped.gsub(MENTION_PATTERN) do |match|
        name = canonical_name(match.delete_prefix("@")) || match.delete_prefix("@")
        %(<span class="mention-token text-accent font-semibold">@#{ERB::Util.html_escape(name)}</span>)
      end
    end

    private

    def canonical_name(name)
      SUPPORTED_AGENT_NAMES.find { |candidate| candidate.casecmp?(name.to_s) }
    end
  end
end
