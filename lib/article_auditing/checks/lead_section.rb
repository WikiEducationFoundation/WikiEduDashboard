# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # The lead is the untitled text before the first heading. Flags a missing
    # lead and an "Introduction"-style heading standing in for one.
    class LeadSection < Check
      KEY = 'structure.lead_section'
      CATEGORY = 'structure'

      INTRO_HEADINGS = %w[introduction intro lead lede].freeze
      NON_PROSE_LINKS = /\[\[(?:File|Image|Category):[^\]]*\]\]/i

      def run(context)
        wikitext = context.parsed_wikitext
        findings = []
        # A page that opens with an "Introduction" heading has one problem, not
        # two, so the heading finding stands in for the missing-lead one.
        findings << missing_lead if missing_lead?(wikitext)
        findings.concat(intro_headings(wikitext))
        output(findings)
      end

      private

      def missing_lead?(wikitext)
        first = wikitext.headings.first
        first && !intro_heading?(first) && lead_empty?(wikitext)
      end

      def intro_heading?(section)
        INTRO_HEADINGS.include?(section.title.downcase)
      end

      # Text before the first heading that is more than templates, comments
      # and whitespace.
      def lead_empty?(wikitext)
        lead = wikitext.masked[0, wikitext.lead.body.length]
        lead.gsub(NON_PROSE_LINKS, '').strip.empty?
      end

      def intro_headings(wikitext)
        wikitext.headings.select { |section| intro_heading?(section) }
                .map { |section| intro_heading(section) }
      end

      def missing_lead
        finding(severity: 'must_fix', **coded(:missing_lead), policy_refs: %w[MOS:LEAD])
      end

      def intro_heading(section)
        finding(severity: 'should_fix', **coded(:intro_heading, heading: section.title),
                section: section.title,
                quote: "#{'=' * section.level}#{section.title}#{'=' * section.level}",
                policy_refs: %w[MOS:LEAD MOS:INTRO])
      end
    end
  end
end
