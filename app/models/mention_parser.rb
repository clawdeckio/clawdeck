class MentionParser
  HANDLE_MENTION_PATTERN = /
    (?<![A-Za-z0-9_.:\/])              # ignore emails or URLs and adjacent word chars
    @(?<handle>[A-Za-z0-9_]+)
  /x.freeze

  class << self
    def extract_handles(text)
      return [] if text.blank?

      text.to_s
        .scan(HANDLE_MENTION_PATTERN)
        .flatten
        .map(&:downcase)
        .uniq
    end

    def extract_agent_ids(text:, agents_scope:)
      handles = extract_handles(text)
      return [] if handles.empty?

      resolved_handles = resolve_handles(handles: handles, agents_scope: agents_scope)
      handles
        .filter_map { |handle| resolved_handles[handle] }
        .uniq
    end

    # Escape raw user text and only inject markup for resolvable @mentions.
    def highlight_mentions(text, agents_scope: nil)
      escaped = ERB::Util.html_escape(text.to_s)
      return escaped if agents_scope.nil?

      handles = extract_handles(text)
      return escaped if handles.empty?

      resolved_handles = resolve_handles(handles: handles, agents_scope: agents_scope)
      return escaped if resolved_handles.empty?

      escaped.gsub(HANDLE_MENTION_PATTERN) do |match|
        handle = match.delete_prefix("@").downcase
        resolved_handles.key?(handle) ? %(<span class="mention">#{match}</span>) : match
      end
    end

    private

    def resolve_handles(handles:, agents_scope:)
      identifier_matches = agents_scope
        .where("LOWER(identifier) IN (?)", handles)
        .pluck(:identifier, :id)
        .each_with_object({}) do |(identifier, id), resolved|
          next if identifier.blank?

          downcased_identifier = identifier.downcase
          resolved[downcased_identifier] ||= id
        end

      unresolved_handles = handles - identifier_matches.keys
      return identifier_matches if unresolved_handles.empty?

      name_matches = agents_scope
        .where("LOWER(name) IN (?)", unresolved_handles)
        .pluck(:name, :id)
        .each_with_object({}) do |(name, id), resolved|
          next if name.blank?

          downcased_name = name.downcase
          resolved[downcased_name] ||= id
        end

      identifier_matches.merge(name_matches) { |_handle, identifier_id, _name_id| identifier_id }
    end
  end
end
