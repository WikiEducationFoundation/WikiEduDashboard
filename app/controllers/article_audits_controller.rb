# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/create_article_audit"
require_dependency "#{Rails.root}/app/services/summarize_article_audit_feedback"
require_dependency "#{Rails.root}/lib/article_auditing/registry"

# Article Audit pages: admins request an audit of a page or revision, list
# recent audits, view reports, re-run checks, and give feedback on findings.
# Reports are built by ArticleAuditWorker; the report page polls #show while an
# audit is running. Anyone who can view a report can give feedback on its
# findings, so #finding_feedback should keep the same access as #show.
class ArticleAuditsController < ApplicationController
  layout 'admin'
  before_action :disallow_indexing
  before_action :require_admin_permissions
  before_action :require_article_audit_feature
  before_action :set_audit, only: %i[show rerun_check finding_feedback]

  RECENT_LIMIT = 50

  def index
    respond_to do |format|
      format.html
      format.json do
        @audits = ArticleAudit.includes(:wiki, :requester).order(id: :desc).limit(RECENT_LIMIT)
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render :index }
      format.json do
        @check_results = @audit.latest_check_results
        @run_counts = @audit.check_results.group(:check_key).count
        @feedback = ArticleAuditFindingFeedback.where(check_result: @check_results,
                                                      user: current_user).index_by(&:finding_id)
        @report = ArticleAuditReportPresenter.new(@audit, @check_results)
      end
    end
  end

  def create
    creator = CreateArticleAudit.new(url: params[:url], requester: current_user)
    if creator.audit
      render json: { id: creator.audit.id }, status: :created
    else
      render json: { error: creator.error }, status: :unprocessable_content
    end
  end

  def rerun_check
    check_key = params[:check_key]
    unless ArticleAuditing::Registry.keys.include?(check_key)
      return render json: { error: 'Unknown check.' }, status: :unprocessable_content
    end
    ArticleAuditCheckWorker.rerun(@audit, check_key)
    head :accepted
  end

  # Saves the current user's feedback on one finding, replacing any they
  # gave before.
  def finding_feedback
    result = @audit.check_results.find_by(id: params[:check_result_id])
    return render json: { error: 'Unknown finding.' }, status: :unprocessable_content unless result
    feedback = result.finding_feedbacks.find_or_initialize_by(
      finding_index: params[:finding_index].to_i, user: current_user
    )
    if feedback.update(feedback_params)
      render json: feedback.slice(*ArticleAuditFindingFeedback::FIELDS)
    else
      render json: { error: feedback.errors.full_messages.to_sentence },
             status: :unprocessable_content
    end
  end

  # Everyone's feedback on findings, tallied by check.
  def feedback
    respond_to do |format|
      format.html { render :index }
      format.json { @summary = SummarizeArticleAuditFeedback.new }
    end
  end

  private

  # Every field, so that one left out or blank is cleared.
  def feedback_params
    ArticleAuditFindingFeedback::FIELDS.index_with { |field| params[field].presence }
  end

  def disallow_indexing
    response.headers['X-Robots-Tag'] = 'noindex, nofollow'
  end

  def require_article_audit_feature
    head :not_found unless Features.article_audit?
  end

  def set_audit
    @audit = ArticleAudit.find(params[:id])
  end
end
