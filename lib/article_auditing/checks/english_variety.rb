# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # National variety of English (MOS:ENGVAR, MOS:RETAIN). Works out the
    # article's established variety from a {{Use ... English}} template on
    # the page or the target article, an English-variety banner on the talk
    # page, or failing those the spelling of the article's first revision;
    # then flags spellings in the audited text from a different variety.
    class EnglishVariety < Check
      KEY = 'mos.engvar'
      CATEGORY = 'mos'
      MAX_FINDINGS = 5
      MIN_MARKERS = 3

      # [American, British/Commonwealth] spelling pairs that are unambiguous
      # markers of variety. (-ize is left out: Oxford spelling uses it too.)
      PAIRS = [
        %w[color colour], %w[colors colours], %w[behavior behaviour], %w[favor favour],
        %w[favorite favourite], %w[honor honour], %w[labor labour], %w[neighbor neighbour],
        %w[center centre], %w[centers centres], %w[theater theatre],
        %w[defense defence], %w[offense offence], %w[analyze analyse], %w[analyzed analysed],
        %w[catalog catalogue], %w[gray grey], %w[aluminum aluminium], %w[traveled travelled],
        %w[modeling modelling], %w[labeled labelled], %w[fetus foetus], %w[tumor tumour],
        %w[pediatric paediatric], %w[anemia anaemia], %w[estrogen oestrogen], %w[edema oedema],
        %w[hemoglobin haemoglobin], %w[leukemia leukaemia], %w[esophagus oesophagus],
        %w[jewelry jewellery], %w[mold mould], %w[plow plough]
      ].freeze
      AMERICAN = PAIRS.map(&:first).to_set.freeze
      BRITISH = PAIRS.map(&:last).to_set.freeze
      # "Use American English", "Use New Zealand English", "Use Oxford English"...
      USE_TEMPLATE = /\A(?:Template:)?Use ([A-Z][A-Za-z ]+?) ?English\z/i
      # Talk-page banners such as {{American English}} and {{British English}}.
      VARIETIES = ['American', 'British', 'Canadian', 'Australian', 'New Zealand', 'Indian',
                   'South African', 'Irish', 'Hong Kong', 'Singapore', 'Pakistani',
                   'Philippine'].freeze
      # The varieties whose spelling can be checked against PAIRS. Canadian
      # English mixes the two (colour and centre, but analyze and aluminum),
      # so it isn't checked.
      SPELLINGS = %i[american british].freeze
      AMERICAN_SPELLING = %w[american philippine].freeze
      TALK_BANNER = /\ATemplate:(#{Regexp.union(VARIETIES).source}) English\z/

      def run(context)
        established = established_variety(context)
        usage = { 'established' => established }
        return output([], usage:) unless SPELLINGS.include?(established)
        output(mismatches(context, established).first(MAX_FINDINGS), usage:)
      end

      private

      # :american (American or Philippine), :canadian, :british (any other
      # Commonwealth variety), or nil if unknown.
      def established_variety(context)
        declared = declared_variety(context)
        return declared if declared
        first_revision = context.wiki_context.target_first_revision_text
        first_revision && spelling_variety(Wikitext.new(first_revision).masked)
      end

      def declared_variety(context)
        match = first_match(use_templates(context), USE_TEMPLATE) ||
                first_match(Array(context.wiki_context.talk_page&.dig(:templates)), TALK_BANNER)
        match && variety_for(match[1])
      end

      # {{Use ... English}} templates on the page and on the target article.
      def use_templates(context)
        on_page = context.parsed_wikitext.templates(/\Ause .*english\z/i).map do |_, text|
          text[2..].split(/[|}]/, 2).first.strip
        end
        on_page + Array(context.wiki_context.target_page&.dig(:templates))
      end

      def first_match(names, pattern)
        names.lazy.filter_map { |name| name.match(pattern) }.first
      end

      def variety_for(name)
        variety = name.strip.downcase
        return :american if AMERICAN_SPELLING.include?(variety)
        return :canadian if variety == 'canadian'
        :british
      end

      def spelling_variety(text)
        words = text.scan(/\b[a-z]+\b/)
        american = words.count { |word| AMERICAN.include?(word) }
        british = words.count { |word| BRITISH.include?(word) }
        return if american + british < MIN_MARKERS || american == british
        american > british ? :american : :british
      end

      def mismatches(context, established)
        foreign = established == :american ? BRITISH : AMERICAN
        wikitext = context.parsed_wikitext
        # Lowercase words only, so that proper names such as "Kennedy Center"
        # don't count.
        wikitext.masked.to_enum(:scan, /\b[a-z]+\b/).filter_map do
          match = Regexp.last_match
          next unless foreign.include?(match[0])
          problem = coded(:mismatch, word: match[0], variety: established.to_s)
          finding(severity: 'should_fix', **problem,
                  section: wikitext.section_at(match.begin(0)).title, quote: match[0],
                  policy_refs: %w[MOS:ENGVAR MOS:RETAIN])
        end.uniq { |finding| finding.dig('location', 'quote') }
      end
    end
  end
end
