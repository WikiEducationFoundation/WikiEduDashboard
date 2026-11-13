# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Book citations with no page numbers (WP:PAGENUM). A {{rp}} right after
    # the citation's ref counts as giving pages.
    class PageNumbers < Check
      KEY = 'sourcing.page_numbers'
      CATEGORY = 'sourcing'
      MAX_FINDINGS = 5

      BOOK_CITATION = /\A(?:cite book|citation)\z/i
      PAGE_PARAMS = /\|\s*(?:pages?|pp?|at|loc|quote-pages?)\s*=\s*[^|}\s]/i
      RP_AFTER = %r{\A[^<\{]*?(?:</ref>|/>)?\s*\{\{\s*rp\s*\|}i

      def run(context)
        text = context.parsed_wikitext.without_comments
        missing = context.parsed_wikitext.templates(BOOK_CITATION).select do |offset, template|
          book?(template) && !template.match?(PAGE_PARAMS) &&
            !text[offset + template.length, 40].to_s.match?(RP_AFTER)
        end
        output(missing.first(MAX_FINDINGS).map { |_, template| missing_finding(template, missing) })
      end

      private

      # {{citation}} is used for many source types; only treat it as a book
      # when it has an ISBN or a book title parameter.
      def book?(template)
        template.match?(/\A\{\{\s*cite book/i) || template.match?(/\|\s*(?:isbn|book-title)\s*=/i)
      end

      def missing_finding(template, missing)
        finding(severity: 'suggestion', **copy(:missing_pages, count: missing.size),
                quote: template.first(80).tr("\n", ' '), policy_refs: %w[WP:PAGENUM])
      end
    end
  end
end
