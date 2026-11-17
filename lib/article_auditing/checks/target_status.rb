# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"

module ArticleAuditing
  module Checks
    # Status of the article being edited that the author should know about:
    # its quality rating when the audited page is a draft of a Featured or
    # Good article, a contentious-topic notice on the talk page, and an
    # active talk page.
    class TargetStatus < Check
      KEY = 'flags.target_status'
      CATEGORY = 'flags'

      QUALITY = { 'FA' => :featured_article, 'GA' => :good_article, 'FL' => :featured_list }.freeze
      CONTENTIOUS = Regexp.union(
        ['Contentious topics/talk notice', 'Ds/talk notice', 'Gs/talk notice', 'Controversial',
         'Calm'].map { |name| /\ATemplate:#{Regexp.escape(name)}/i }
      )
      ACTIVE_TALK = 10

      def applies_to?(context)
        context.wiki_context.target_exists?
      end

      def run(context)
        wiki_context = context.wiki_context
        findings = [quality_finding(context, wiki_context), contentious_finding(wiki_context),
                    talk_activity_finding(wiki_context)]
        output(findings.compact)
      end

      private

      # In mainspace, PageFlags already reports the article's own FA/GA templates.
      def quality_finding(context, wiki_context)
        flag = QUALITY[wiki_context.target_page[:assessment_class]]
        return if flag.nil? || context.mainspace?
        finding(severity: 'info', **coded(flag, article: wiki_context.target_page[:title]),
                policy_refs: ["WP:#{wiki_context.target_page[:assessment_class]}"])
      end

      def contentious_finding(wiki_context)
        talk_templates = Array(wiki_context.talk_page&.dig(:templates))
        notice = talk_templates.find { |name| name.match?(CONTENTIOUS) }
        return if notice.nil?
        finding(severity: 'info', **coded(:contentious, notice: notice.delete_prefix('Template:')),
                policy_refs: %w[WP:CTOP])
      end

      def talk_activity_finding(wiki_context)
        edits = wiki_context.talk_page&.dig(:recent_edits).to_i
        return if edits < ACTIVE_TALK
        finding(severity: 'info', **coded(:active_talk, edits:), policy_refs: %w[WP:TALK])
      end
    end
  end
end
