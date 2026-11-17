# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/finding_anchors"
require_dependency "#{Rails.root}/lib/article_auditing/rendered_article"

# The findings and annotated article for an Article Audit report. Gives each
# finding an id ("<result id>-<index>") and the kind of place it's anchored to
# in the article (see ArticleAuditing::FindingAnchors), or nil for findings
# shown apart from the text.
class ArticleAuditReportPresenter
  def initialize(audit, check_results)
    @audit = audit
    @findings = check_results.to_h do |result|
      [result.id, Array(result.findings).each_with_index.map do |finding, index|
        finding.merge('id' => "#{result.id}-#{index}")
      end]
    end
  end

  def findings(result)
    @findings[result.id].map { |finding| finding.merge('anchor' => anchors.anchors[finding['id']]) }
  end

  # The rendered article with the findings marked, or nil when the revision
  # can't be fetched (see ArticleAuditing::RenderedArticle).
  def article_html
    article ? anchors.html : nil
  end

  private

  def article
    return @article if defined?(@article)
    @article = ArticleAuditing::RenderedArticle.fetch(@audit.wiki, @audit.mw_rev_id)
  end

  def anchors
    @anchors ||= ArticleAuditing::FindingAnchors.new(
      html: article&.dig(:html), wikitext: article&.dig(:wikitext),
      base_url: @audit.wiki.base_url, findings: @findings.values.flatten
    )
  end
end
