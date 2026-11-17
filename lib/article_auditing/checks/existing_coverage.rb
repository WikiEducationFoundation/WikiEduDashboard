# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/llm_check"

module ArticleAuditing
  module Checks
    # For a new article: whether the topic is already covered in an existing
    # article under another name, and if so, which content from the draft
    # would be worth adding there instead. The candidates come from a search
    # of the wiki for the article's title.
    # Prompt: config/article_audit/prompts/new_article.existing_coverage.md
    class ExistingCoverage < LlmCheck
      KEY = 'new_article.existing_coverage'
      CATEGORY = 'new_article'
      ARTIFACTS = %w[coverage].freeze

      def applies_to?(context)
        context.new_article? && context.wiki_context.target_title.present?
      end

      private

      def user_content(context)
        related = context.wiki_context.related_articles
        <<~CONTENT
          #{prompt}
          <search_results query="#{CGI.escapeHTML(context.wiki_context.target_title)}">
          #{related.map { |article| related_article(article) }.join("\n")}
          </search_results>
        CONTENT
      end

      def related_article(article)
        <<~ARTICLE.strip
          <result title="#{CGI.escapeHTML(article[:title])}" description="#{CGI.escapeHTML(article[:description].to_s)}">
          #{article[:extract]}
          </result>
        ARTICLE
      end
    end
  end
end
