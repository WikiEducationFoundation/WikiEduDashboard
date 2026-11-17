# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # Proposes categories for a new article, and reviews an existing
    # article's categories for ones that are too broad or missing. Candidates
    # are the categories of the articles the page links to, so the proposals
    # stay grounded in the wiki's actual category tree; every proposed
    # category is then checked against the wiki and marked if it doesn't
    # exist.
    # Prompt: config/article_audit/prompts/new_article.categories.md
    class Categories < LlmCheck
      KEY = 'new_article.categories'
      CATEGORY = 'new_article'
      ARTIFACTS = %w[categories].freeze
      MAX_CANDIDATES = 40
      WIKILINK = /\[\[([^\[\]|#:]+)(?:#[^\[\]|]*)?(?:\|[^\[\]]*)?\]\]/
      PAGE_CATEGORY = /\[\[\s*Category\s*:\s*([^\]|]+)/i

      def applies_to?(context)
        context.new_article? || context.mainspace?
      end

      def run(context)
        result = super
        proposed = Array(result.artifacts['categories'])
        return result if proposed.empty?
        checked = mark_existing(context, proposed)
        missing = checked.count { |category| !category['exists'] }
        output(result.findings, artifacts: result.artifacts.merge('categories' => checked),
                                usage: result.usage.merge('nonexistent_categories' => missing))
      end

      private

      def mark_existing(context, proposed)
        titles = proposed.map { |category| category_title(category['name']) }
        existing = context.wiki_context.existing_titles(titles)
        proposed.zip(titles).map do |category, title|
          category.merge('exists' => existing.key?(title))
        end
      end

      def category_title(name)
        "Category:#{name.to_s.delete_prefix('Category:').strip}"
      end

      def user_content(context)
        <<~CONTENT
          #{prompt}
          <current_categories>
          #{current_categories(context).join("\n")}
          </current_categories>
          <candidate_categories note="categories of the articles this page links to, with how many of them are in each">
          #{candidates(context).map { |name, count| "#{name} (#{count})" }.join("\n")}
          </candidate_categories>
        CONTENT
      end

      def current_categories(context)
        context.wikitext.scan(PAGE_CATEGORY).flatten.map { |name| "Category:#{name.strip}" }
      end

      def candidates(context)
        linked = context.parsed_wikitext.masked.scan(WIKILINK).flatten.map(&:strip).uniq
        context.wiki_context.category_counts(linked).sort_by { |name, count| [-count, name] }
               .first(MAX_CANDIDATES)
      end
    end
  end
end
