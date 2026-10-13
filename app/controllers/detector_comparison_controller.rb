# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/summarize_detector_comparison"
require_dependency "#{Rails.root}/app/services/summarize_known_human_texts"
require_dependency "#{Rails.root}/app/services/describe_detector_comparison_unit"
require_dependency "#{Rails.root}/app/services/render_detector_comparison_intro"

# Admin pages presenting the AI detector comparison data: an index with the
# operator's introduction and conclusions, the 16-topic dataset (generated and
# Agpedia texts with the human texts they are paired with), the known-human
# dataset, and every detector's results. Wiki Education Dashboard only, where
# the comparison samples are collected.
class DetectorComparisonController < ApplicationController
  layout 'admin'
  before_action :require_wiki_ed
  before_action :require_admin_permissions

  def index
    respond_to do |format|
      format.html
      format.json do
        render json: { intro: RenderDetectorComparisonIntro.new.result,
                       counts: { topics: SummarizeDetectorComparison.new.unit_ids.size,
                                 known_human: SummarizeKnownHumanTexts.new.unit_ids.size } }
      end
    end
  end

  def topics
    respond_to do |format|
      format.html { render :index }
      format.json do
        render json: SummarizeDetectorComparison.new.result
          .merge(intro: RenderDetectorComparisonIntro.new.result)
      end
    end
  end

  def known_human
    respond_to do |format|
      format.html { render :index }
      format.json do
        render json: SummarizeKnownHumanTexts.new.result
          .merge(intro: RenderDetectorComparisonIntro.new.result)
      end
    end
  end

  # A topic's page is drawn from the same data as the 16-topic dataset.
  def topic
    render :index
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
