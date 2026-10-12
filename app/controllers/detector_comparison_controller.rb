# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/summarize_detector_comparison"
require_dependency "#{Rails.root}/app/services/describe_detector_comparison_unit"

# Admin page presenting the AI detector comparison data: generated and Agpedia
# texts, the human texts they are paired with, and every detector's results.
# Wiki Education Dashboard only, where the comparison samples are collected.
class DetectorComparisonController < ApplicationController
  layout 'admin'
  before_action :require_wiki_ed
  before_action :require_admin_permissions

  def index
    respond_to do |format|
      format.html
      format.json { render json: SummarizeDetectorComparison.new.result }
    end
  end

  def unit
    respond_to do |format|
      format.html { render :index }
      format.json { render json: DescribeDetectorComparisonUnit.new(params[:id]).result }
    end
  end

  private

  def require_wiki_ed
    raise ActionController::RoutingError, 'Not Found' unless Features.wiki_ed?
  end
end
