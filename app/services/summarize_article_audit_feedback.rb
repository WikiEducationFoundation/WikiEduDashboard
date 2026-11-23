# frozen_string_literal: true

# Tallies everyone's ArticleAuditFindingFeedback, to show which kinds of
# finding are accurate and worth showing to program participants.
#
# - groups: one per check, split by finding code for findings from code; LLM
#   findings have no code, so each LLM check is one group. Each has the
#   number of responses and the count of each answer to both questions.
# - responses: every response with its finding, newest first.
class SummarizeArticleAuditFeedback
  attr_reader :groups, :responses

  def initialize
    @responses = []
    @groups = []
    summarize
  end

  private

  def summarize
    @responses = ArticleAuditFindingFeedback
                 .includes(:user, check_result: :article_audit)
                 .order(updated_at: :desc)
                 .filter_map { |feedback| response(feedback) }
    @groups = @responses.group_by { |response| response.values_at(:check_key, :code) }
                        .map { |(check_key, code), responses| group(check_key, code, responses) }
                        .sort_by { |group| [group[:check_key], group[:code].to_s] }
  end

  def response(feedback)
    finding = feedback.finding
    return unless finding
    audit = feedback.check_result.article_audit
    {
      audit_id: audit.id, article_title: audit.article_title, finding_id: feedback.finding_id,
      check_key: feedback.check_result.check_key, code: finding['code'],
      title: finding['title'].presence, severity: finding['severity'],
      user: feedback.user.username, updated_at: feedback.updated_at,
      **feedback.slice(*ArticleAuditFindingFeedback::FIELDS).symbolize_keys
    }
  end

  def group(check_key, code, responses)
    {
      check_key:, code:, responses: responses.size,
      accurate: tally(responses, :accurate, ArticleAuditFindingFeedback::ACCURATE_OPTIONS),
      show_to_participants: tally(responses, :show_to_participants,
                                  ArticleAuditFindingFeedback::SHOW_OPTIONS)
    }
  end

  def tally(responses, field, options)
    counts = responses.map { |response| response[field] }.tally
    options.index_with { |option| counts.fetch(option, 0) }
  end
end
