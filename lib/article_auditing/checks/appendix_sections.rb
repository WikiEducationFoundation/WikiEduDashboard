# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Standard appendix sections (See also, References, Further reading,
    # External links...) per MOS:ORDER and MOS:APPENDIX: their order, their
    # names, and content sections placed after them.
    class AppendixSections < Check
      KEY = 'mos.appendix_sections'
      CATEGORY = 'mos'

      # Position of each standard appendix in MOS:ORDER. Sections sharing a
      # rank may appear in either order relative to each other.
      RANKS = {
        'works' => 0, 'publications' => 0, 'discography' => 0, 'filmography' => 0,
        'see also' => 1,
        'notes' => 2, 'footnotes' => 2, 'references' => 2, 'citations' => 2,
        'sources' => 2, 'bibliography' => 2, 'works cited' => 2,
        'further reading' => 3,
        'external links' => 4
      }.freeze
      # Content sections may follow the "works" group, so only these count as
      # the start of the appendices.
      APPENDIX_START_RANK = 1

      # Common non-standard names and the standard name to use instead.
      RENAMES = {
        'external link' => 'External links',
        'links' => 'External links',
        'external sources' => 'External links',
        'further readings' => 'Further reading',
        'related articles' => 'See also',
        'related pages' => 'See also',
        'reference' => 'References',
        'reference list' => 'References',
        'works cited list' => 'Works cited'
      }.freeze

      def run(context)
        sections = context.parsed_wikitext.headings.select { |section| section.level == 2 }
        findings = rename_findings(sections)
        findings << order_finding(sections) if out_of_order?(sections)
        findings.concat(content_after_appendix_findings(sections))
        output(findings)
      end

      private

      def rank(section)
        RANKS[section.title.downcase] || RANKS[RENAMES[section.title.downcase]&.downcase]
      end

      def rename_findings(sections)
        sections.filter_map do |section|
          standard = RENAMES[section.title.downcase] || standard_case(section.title)
          next if standard.nil? || standard == section.title
          finding(severity: 'suggestion', **coded(:rename, heading: section.title, standard:),
                  section: section.title, quote: "==#{section.title}==",
                  suggestion: "==#{standard}==", policy_refs: %w[MOS:APPENDIX MOS:HEADINGS])
        end
      end

      # "External Links" -> "External links", for standard appendix names only.
      def standard_case(title)
        return unless RANKS.key?(title.downcase)
        title.downcase.upcase_first
      end

      def out_of_order?(sections)
        ranks = sections.filter_map { |section| rank(section) }
        ranks != ranks.sort
      end

      def order_finding(sections)
        present = sections.select { |section| rank(section) }.map(&:title)
        expected = present.sort_by.with_index { |title, i| [rank_for_title(title), i] }
        finding(severity: 'should_fix',
                **coded(:order, actual: present.join(', '), expected: expected.join(', ')),
                suggestion: expected.join(', '), policy_refs: %w[MOS:ORDER])
      end

      def rank_for_title(title)
        RANKS[title.downcase] || RANKS[RENAMES[title.downcase]&.downcase] || 0
      end

      # Content sections (not standard appendices) after the first appendix.
      def content_after_appendix_findings(sections)
        first_appendix = sections.index { |section| rank(section).to_i >= APPENDIX_START_RANK }
        return [] if first_appendix.nil?
        sections.drop(first_appendix + 1).select { |section| rank(section).nil? }.map do |section|
          finding(severity: 'should_fix', **coded(:content_after_appendix, heading: section.title),
                  section: section.title, quote: "==#{section.title}==",
                  policy_refs: %w[MOS:ORDER])
        end
      end
    end
  end
end
