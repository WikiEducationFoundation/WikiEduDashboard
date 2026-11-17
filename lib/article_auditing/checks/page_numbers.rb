# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Book citations with no page numbers (WP:PAGENUM). A {{rp}} right after
    # the citation's ref counts as giving pages. On a page that cites with
    # shortened footnotes ({{sfn}}, {{harvnb}}...), book citations outside
    # <ref> tags are the full entries those footnotes point to, which carry
    # no page numbers by design, so they are left alone.
    class PageNumbers < Check
      KEY = 'sourcing.page_numbers'
      CATEGORY = 'sourcing'
      MAX_FINDINGS = 5

      BOOK_CITATION = /\A(?:cite book|citation)\z/i
      PAGE_PARAMS = /\|\s*(?:pages?|pp?|at|loc|quote-pages?)\s*=\s*[^|}\s]/i
      RP_AFTER = %r{\A[^<\{]*?(?:</ref>|/>)?\s*\{\{\s*rp\s*\|}i
      SHORT_FOOTNOTE = /\{\{\s*(?:sfnm?|sfnp|harvnb|harvp|harv|harvtxt)\s*\|/i

      def run(context)
        wikitext = context.parsed_wikitext
        text = wikitext.without_comments
        candidates = wikitext.templates(BOOK_CITATION)
        candidates = in_refs(candidates, text) if text.match?(SHORT_FOOTNOTE)
        missing = candidates.select do |offset, template|
          book?(template) && !template.match?(PAGE_PARAMS) &&
            !text[offset + template.length, 40].to_s.match?(RP_AFTER)
        end
        output(missing.first(MAX_FINDINGS).map { |_, template| missing_finding(template, missing) })
      end

      private

      # The templates that sit inside <ref> tags.
      def in_refs(templates, text)
        spans = text.to_enum(:scan, Wikitext::REF).map { Regexp.last_match.offset(0) }
        templates.select do |offset, _|
          spans.any? { |start, finish| offset.between?(start, finish - 1) }
        end
      end

      # {{citation}} is used for many source types; only treat it as a book
      # when it has an ISBN or a book title parameter.
      def book?(template)
        template.match?(/\A\{\{\s*cite book/i) || template.match?(/\|\s*(?:isbn|book-title)\s*=/i)
      end

      def missing_finding(template, missing)
        finding(severity: 'suggestion', **coded(:missing_pages, count: missing.size),
                quote: template.first(80).tr("\n", ' '), policy_refs: %w[WP:PAGENUM])
      end
    end
  end
end
