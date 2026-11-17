# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # External links in the article body (outside citations and the
    # appendix sections), which WP:EL says belong in External links or in a
    # citation instead.
    class ExternalLinksInBody < Check
      KEY = 'links.external_links_in_body'
      CATEGORY = 'links'
      MAX_FINDINGS = 10

      # Sections where external links are expected.
      LINK_SECTIONS = ['external links', 'further reading', 'references', 'notes', 'sources',
                       'bibliography', 'works cited', 'citations', 'footnotes'].freeze
      EXTERNAL_LINK = %r{\[?(?:https?:)?//[^\s\]|<\}]+}i

      def run(context)
        wikitext = context.parsed_wikitext
        output(link_findings(wikitext).first(MAX_FINDINGS))
      end

      private

      # Searches each section's masked text (refs, templates and comments
      # blanked out), skipping the sections where external links belong.
      def link_findings(wikitext)
        wikitext.sections.flat_map do |section|
          next [] if section.title && LINK_SECTIONS.include?(section.title.downcase)
          section_findings(wikitext.masked_body(section), section)
        end
      end

      def section_findings(masked_body, section)
        masked_body.to_enum(:scan, EXTERNAL_LINK).map do
          link = Regexp.last_match(0)
          finding(severity: 'should_fix', **coded(:link_in_body),
                  section: section.title, quote: link.delete_prefix('['),
                  policy_refs: %w[WP:EL MOS:LINKSTYLE])
        end
      end
    end
  end
end
