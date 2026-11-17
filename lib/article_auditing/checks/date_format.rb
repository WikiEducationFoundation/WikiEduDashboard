# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Dates written in a format other than the one the page declares with
    # {{Use dmy dates}} or {{Use mdy dates}}, or a mix of both formats on a
    # page that declares neither (MOS:DATEUNIFY). Citation templates are
    # ignored: they display their dates in the declared format anyway, and
    # citations may use a different format from the text in any case.
    class DateFormat < Check
      KEY = 'mos.date_format'
      CATEGORY = 'mos'
      MAX_FINDINGS = 5

      MONTHS = '(?:January|February|March|April|May|June|July|August|September|October|' \
               'November|December)'
      DMY = /\b\d{1,2} #{MONTHS} \d{4}\b/
      MDY = /\b#{MONTHS} \d{1,2}, \d{4}\b/
      USE_DMY = /\{\{\s*use dmy dates/i
      USE_MDY = /\{\{\s*use mdy dates/i
      CITATION = /\A(?:cite[ _]|citation\z)/i

      def run(context)
        text = without_citations(context.parsed_wikitext)
        return output(mismatches(text, MDY, 'dmy')) if text.match?(USE_DMY)
        return output(mismatches(text, DMY, 'mdy')) if text.match?(USE_MDY)
        output(mixed_formats(text))
      end

      private

      def without_citations(wikitext)
        text = wikitext.without_comments.dup
        wikitext.templates(CITATION).each do |offset, template|
          text[offset, template.length] = ' ' * template.length
        end
        text
      end

      def mismatches(text, wrong_format, declared)
        matches = scan(text, wrong_format)
        matches.first(MAX_FINDINGS).map do |match|
          finding(severity: 'should_fix', **coded(:mismatch, declared:, count: matches.size),
                  quote: match, policy_refs: %w[MOS:DATEUNIFY MOS:DATEFORMAT])
        end
      end

      def mixed_formats(text)
        dmy = scan(text, DMY)
        mdy = scan(text, MDY)
        return [] if dmy.empty? || mdy.empty?
        minority = dmy.size < mdy.size ? dmy : mdy
        [finding(severity: 'suggestion', **coded(:mixed, dmy: dmy.size, mdy: mdy.size),
                 quote: minority.first, policy_refs: %w[MOS:DATEUNIFY MOS:DATEVAR])]
      end

      def scan(text, pattern)
        text.scan(pattern)
      end
    end
  end
end
