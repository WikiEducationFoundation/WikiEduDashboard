# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"
require_dependency "#{Rails.root}/lib/article_auditing/checks/appendix_sections"

module ArticleAuditing
  module Checks
    # The same article linked more than once in the body (MOS:DUPLINK). A term
    # may be linked once in the lead and again at its first mention in the
    # body; links inside templates such as infoboxes, and in appendix
    # sections such as See also, don't count.
    class DuplicateLinks < Check
      KEY = 'links.duplicate_links'
      CATEGORY = 'links'
      MAX_FINDINGS = 5

      WIKILINK = /\[\[([^\[\]|#]+)(?:#[^\[\]|]*)?(?:\|[^\[\]]*)?\]\]/
      NON_ARTICLE = /\A\s*:?\s*(?:file|image|category|media|[a-z]{2,3}(?:-[a-z]+)?)\s*:/i

      def run(context)
        repeated = body_links(context.parsed_wikitext).group_by { |link| link[:target] }
                                                      .select { |_, links| links.size > 1 }
        # Most-repeated first, so the cap keeps the worst cases.
        findings = repeated.sort_by { |_, links| -links.size }
                           .map { |target, links| repeat_finding(target, links) }
        output(findings.first(MAX_FINDINGS))
      end

      private

      def body_links(wikitext)
        body_sections = wikitext.headings.reject do |section|
          AppendixSections::RANKS.key?(section.title.downcase)
        end
        body_sections.flat_map { |section| links_in(wikitext, section) }
      end

      def links_in(wikitext, section)
        wikitext.masked_body(section).to_enum(:scan, WIKILINK).filter_map do
          match = Regexp.last_match
          next if match[1].match?(NON_ARTICLE)
          { target: normalize(match[1]), text: match[0], section: section.title }
        end
      end

      def normalize(target)
        target.tr('_', ' ').squeeze(' ').strip.upcase_first
      end

      def repeat_finding(target, links)
        repeat = links[1]
        finding(severity: 'suggestion', **coded(:repeated_link, target:, count: links.size),
                section: repeat[:section], quote: repeat[:text], policy_refs: %w[MOS:DUPLINK])
      end
    end
  end
end
