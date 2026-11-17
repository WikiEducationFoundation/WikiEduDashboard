# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"
require_dependency "#{Rails.root}/lib/article_auditing/checks/lead_section"

module ArticleAuditing
  module Checks
    # Bold, underlining and other font styling in the article body
    # (MOS:BOLD, MOS:UNDERLINE, MOS:FONTSIZE). Bold in the lead is allowed,
    # since the lead bolds the article's title; so is bold in a draft's
    # "Lead"-style section, which is the lead of the article being drafted.
    class Emphasis < Check
      KEY = 'mos.emphasis'
      CATEGORY = 'mos'
      MAX_FINDINGS = 8

      PATTERNS = [
        { regex: /(?<!')'''(?!')[^'\n]+?'''(?!')/, copy: :bold, policy: 'MOS:BOLD' },
        { regex: %r{<u>.*?</u>}i, copy: :underline, policy: 'MOS:UNDERLINE' },
        { regex: /<(?:big|font|small)\b[^>]*>/i, copy: :font, policy: 'MOS:FONTSIZE' }
      ].freeze

      def run(context)
        wikitext = context.parsed_wikitext
        body_sections = wikitext.headings.reject do |section|
          LeadSection::INTRO_HEADINGS.include?(section.title.downcase)
        end
        findings = body_sections.flat_map do |section|
          section_findings(wikitext.masked_body(section), section)
        end
        output(findings.first(MAX_FINDINGS))
      end

      private

      def section_findings(body, section)
        PATTERNS.flat_map do |pattern|
          body.to_enum(:scan, pattern[:regex]).filter_map do
            match = Regexp.last_match
            next if definition_or_table_line?(body, match.begin(0))
            finding(severity: 'suggestion', **coded(pattern[:copy]), section: section.title,
                    quote: match[0], policy_refs: [pattern[:policy]])
          end
        end
      end

      # Bold is expected in definition-list terms (;) and table headers (!).
      def definition_or_table_line?(body, index)
        line_start = body.rindex("\n", index) || -1
        body[line_start + 1]&.match?(/[;!]/)
      end
    end
  end
end
