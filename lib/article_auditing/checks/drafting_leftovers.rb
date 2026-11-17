# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Scaffolding from Wiki Education's sandbox and draft templates that has
    # to come out before the content goes live: sandbox templates, draft
    # headings such as "Article body", and markers such as "[TEMP]". The
    # markers are listed in config/article_audit/drafting_markers.yml.
    class DraftingLeftovers < Check
      KEY = 'structure.drafting_leftovers'
      CATEGORY = 'structure'
      MARKERS_PATH = Rails.root.join('config/article_audit/drafting_markers.yml')

      def run(context)
        wikitext = context.parsed_wikitext
        severity = context.mainspace? ? 'must_fix' : 'should_fix'
        findings = template_findings(wikitext) + heading_findings(wikitext) +
                   text_findings(wikitext)
        findings = findings.uniq { |f| f.dig('location', 'quote') }
        output(findings.map { |f| f.merge('severity' => severity) })
      end

      private

      def markers
        @markers ||= YAML.load_file(MARKERS_PATH)
      end

      def patterns(kind)
        markers.fetch(kind, []).map { |pattern| Regexp.new(pattern, Regexp::IGNORECASE) }
      end

      def template_findings(wikitext)
        wikitext.templates(Regexp.union(patterns('templates'))).map do |_, template|
          leftover(:template, template.first(80).tr("\n", ' '), nil)
        end
      end

      def heading_findings(wikitext)
        heading_patterns = patterns('headings')
        wikitext.headings.select { |s| heading_patterns.any? { |p| s.title.match?(p) } }.map do |s|
          marks = '=' * s.level
          leftover(:heading, "#{marks}#{s.title}#{marks}", s.title)
        end
      end

      def text_findings(wikitext)
        patterns('text').flat_map do |pattern|
          wikitext.without_comments.to_enum(:scan, pattern).map do
            match = Regexp.last_match
            leftover(:text, match[0], wikitext.section_at(match.begin(0)).title)
          end
        end
      end

      def leftover(kind, quote, section)
        finding(severity: 'should_fix', **coded(kind), section:, quote:)
      end
    end
  end
end
