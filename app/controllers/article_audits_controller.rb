# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/create_article_audit"
require_dependency "#{Rails.root}/lib/article_auditing/registry"

# Admin-only Article Audit pages: request an audit of a page or revision, list
# recent audits, and view a report. Reports are built by ArticleAuditWorker;
# the report page polls #show while an audit is running.
class ArticleAuditsController < ApplicationController
  layout 'admin'
  before_action :require_admin_permissions
  before_action :require_article_audit_feature
  before_action :set_audit, only: %i[show rerun_check]

  RECENT_LIMIT = 50

  def index
    respond_to do |format|
      format.html
      format.json {
 @audits = ArticleAudit.includes(:wiki, :requester).order(id: :desc).limit(RECENT_LIMIT) }
    end
  end

  def show
    respond_to do |format|
      format.html { render :index }
      format.json do
        @check_results = @audit.latest_check_results
        @run_counts = @audit.check_results.group(:check_key).count
      end
    end
  end

  def create
    creator = CreateArticleAudit.new(url: params[:url], requester: current_user)
    if creator.audit
      render json: { id: creator.audit.id }, status: :created
    else
      render json: { error: I18n.t("article_audit.create_errors.#{creator.error}") },
             status: :unprocessable_content
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

  private

  def require_article_audit_feature
    head :not_found unless Features.article_audit?
  end

  def set_audit
    @audit = ArticleAudit.find(params[:id])
  end
end
