# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Notes that the page carries a status the author should know about
    # before editing it: Featured or Good article, a current event, or a
    # recent death.
    class PageFlags < Check
      KEY = 'flags.page_status'
      CATEGORY = 'flags'

      FLAGS = {
        featured_article: /\Afeatured article\z/i,
        good_article: /\Agood article\z/i,
        current_event: /\Acurrent(?: event| related|)\z/i,
        recent_death: /\Arecent death/i
      }.freeze
      POLICY_REFS = {
        featured_article: %w[WP:FA], good_article: %w[WP:GA],
        current_event: %w[WP:CURRENT], recent_death: %w[WP:BLP WP:BDP]
      }.freeze

      def run(context)
        wikitext = context.parsed_wikitext
        findings = FLAGS.filter_map do |flag, pattern|
          offset, template = wikitext.templates(pattern).first
          next if offset.nil?
          finding(severity: 'info', **coded(flag), quote: template.first(60),
                  policy_refs: POLICY_REFS[flag])
        end
        output(findings)
      end
    end
  end
end
