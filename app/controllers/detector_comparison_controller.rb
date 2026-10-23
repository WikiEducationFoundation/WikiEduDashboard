# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/publish_detector_comparison"
require_dependency "#{Rails.root}/app/services/render_detector_comparison_intro"

# Public pages presenting the AI detector comparison data: an index with the
# operator's introduction and conclusions, the 16-topic dataset (generated and
# Agpedia texts with the human texts they are paired with), the known-human
# dataset, and every detector's results. Wiki Education Dashboard only, where
# the comparison samples are collected. The data is served from the files
# PublishDetectorComparison writes, so requests do no work beyond sending them;
# the introduction is read from its config file on each request.
class DetectorComparisonController < ApplicationController
  layout 'admin'
  before_action :require_wiki_ed

  def index
    respond_to do |format|
      format.html
      format.json do
        manifest = PublishDetectorComparison.manifest || {}
        render json: { intro: RenderDetectorComparisonIntro.new.result,
                       counts: manifest['counts'], published_at: manifest['published_at'] }
      end
    end
  end

  def topics
    respond_to do |format|
      format.html { render :index }
      format.json { send_published 'topics' }
    end
  end

  def known_human
    respond_to do |format|
      format.html { render :index }
      format.json { send_published 'known_human' }
    end
  end

  # A topic's page is drawn from the same data as the 16-topic dataset.
  def topic
    render :index
  end

  def unit
    respond_to do |format|
      format.html { render :index }
      format.json { send_published "units/#{params[:id].to_i}" }
    end
  end

  private

  # A published file, gzipped when the browser takes it. Only units the page lists have one.
  # It is read from the publication's own directory, so a publication that lands mid-request
  # can't pair one publication's ETag with another's content.
  def send_published(name)
    file = PublishDetectorComparison.published_file(name)&.realpath
    raise ActionController::RoutingError, 'Not Found' unless file

    response.headers['Vary'] = 'Accept-Encoding'
    return unless stale?(etag: file.to_s, last_modified: file.mtime)

    filename = file.basename.to_s
    if request.headers['Accept-Encoding'].to_s.include?('gzip')
      response.headers['Content-Encoding'] = 'gzip'
      file = "#{file}.gz"
    end
    send_file file, type: 'application/json', disposition: 'inline', filename:
  end

  def require_wiki_ed
    raise ActionController::RoutingError, 'Not Found' unless Features.wiki_ed?
  end
end
