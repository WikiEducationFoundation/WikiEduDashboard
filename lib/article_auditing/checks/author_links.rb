# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Citation authors, and the journals, newspapers, magazines and
    # publishers they appeared in, that have their own Wikipedia article but
    # aren't linked from the citation (|author-link=, or a wikilinked |work=).
    # Candidates are filtered by the matching article's short description, so
    # that, say, |journal=Nature isn't linked to the article about nature.
    class AuthorLinks < Check
      KEY = 'sourcing.author_links'
      CATEGORY = 'sourcing'
      MAX_FINDINGS = 10

      CITATION = /\A(?:cite\s|citation\z)/i
      WORK_PARAMS = %w[journal newspaper magazine work website periodical publisher].freeze
      WORK_DESCRIPTION = /journal|newspaper|magazine|periodical|publish|press|news|website|
                          broadcast|media|company|organi[sz]ation|society|university/ix
      # Biographies' short descriptions almost always give dates.
      PERSON_DESCRIPTION = /\b1[5-9]\d\d\b|\b20\d\d\b|\bborn\b/i

      def run(context)
        candidates = context.parsed_wikitext.templates(CITATION).flat_map do |_, template|
          author_candidates(template) + work_candidates(template)
        end.uniq { |candidate| [candidate[:kind], candidate[:name]] }
        existing = context.wiki_context.existing_titles(candidates.flat_map { |c| c[:lookups] })
        findings = candidates.filter_map { |candidate| link_finding(candidate, existing) }
        output(findings.first(MAX_FINDINGS))
      end

      private

      def params(template)
        template.scan(/\|\s*([a-z0-9-]+)\s*=\s*([^|}]*)/i).to_h do |name, value|
          [name.downcase, value.strip]
        end
      end

      def author_candidates(template)
        values = params(template)
        authors(values).filter_map do |index, name|
          next if name.include?('[[') || values["author-link#{index}"].present? ||
                  values["author#{index}-link"].present? || name.split.size < 2
          { kind: :author, name:, lookups: [name], param: index }
        end
      end

      # [[index, "First Last"]] for last/first pairs and author= values.
      def authors(values)
        values.keys.grep(/\A(?:last|author|surname)(\d*)\z/).filter_map do |key|
          index = key[/\d+/].to_s
          last = values[key]
          next if last.blank?
          first = values["first#{index}"] || values["given#{index}"]
          [index, [first, last].compact_blank.join(' ')]
        end
      end

      def work_candidates(template)
        values = params(template)
        WORK_PARAMS.filter_map do |param|
          name = values[param]
          next if name.blank? || name.include?('[[') || name.match?(%r{https?://})
          { kind: :work, name:, lookups: work_lookups(param, name), param: }
        end
      end

      # Disambiguated titles such as "Nature (journal)" are tried first.
      TYPED_WORKS = %w[journal newspaper magazine].freeze

      def work_lookups(param, name)
        [("#{name} (#{param})" if TYPED_WORKS.include?(param)), name].compact
      end

      def link_finding(candidate, existing)
        match = candidate[:lookups].lazy.map { |title| existing[title] }.find do |page|
          page && page[:description].to_s.match?(description_pattern(candidate))
        end
        return if match.nil?
        problem = coded(candidate[:kind], name: candidate[:name], article: match[:title])
        finding(severity: 'suggestion', **problem, quote: candidate[:name],
                suggestion: suggestion(candidate, match[:title]),
                policy_refs: %w[WP:CITEVAR MOS:LINK])
      end

      def description_pattern(candidate)
        candidate[:kind] == :author ? PERSON_DESCRIPTION : WORK_DESCRIPTION
      end

      def suggestion(candidate, title)
        return "|author-link#{candidate[:param]}=#{title}" if candidate[:kind] == :author
        link = title == candidate[:name] ? title : "#{title}|#{candidate[:name]}"
        "|#{candidate[:param]}=[[#{link}]]"
      end
    end
  end
end
