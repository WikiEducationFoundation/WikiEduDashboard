# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ai/ai_detector"
require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

class AiToolsController < ApplicationController
  before_action :require_admin_permissions

  def show; end

  def compare_ai_detectors
    text = extract_plain_text
    if text
      detect_ai_from_multiple_resources text
      create_revision_ai_scores_for_multiple_resources
    end
    render 'show'
  end

  private

  MAX_CONCURRENCY = 6

  # The detectors whose checkbox was ticked, in registry order.
  def selected_detectors
    @selected_detectors ||= AiDetector.keys
                                      .select { |key| params[key.to_sym] }
                                      .map { |key| AiDetector.for(key) }
  end

  def detect_ai_from_multiple_resources(text)
    pool = Concurrent::FixedThreadPool.new(MAX_CONCURRENCY)
    @results = Concurrent::Hash.new
    @errors = Concurrent::Hash.new

    selected_detectors.each do |detector|
      pool.post { detect_ai(detector, text) }
    end
    pool.shutdown && pool.wait_for_termination
  end

  def detect_ai(detector, text)
    @results[detector.key] = detector.client.inference text
  rescue *AiDetector.recoverable_errors => e
    @errors[detector.key] = e.message
  end

  # Returns false when the URL selects a revision we cannot resolve (diff=next),
  # so that nothing unrelated gets scored in its place.
  def parse_url
    @url = params[:article_or_diff_url]
    parser = WikiUrlParser.new(@url)
    @wiki = parser.wiki
    @article_title = parser.title

    target = parser.revision_target
    if target.nil? && parser.revision_selector?
      @url_error = "Unsupported URL: #{@url}"
      return false
    end
    # A URL with only a page title has no revision, so fetch the latest one.
    # Example: https://en.wikipedia.org/wiki/Greater_Cooch_Behar_People%27s_Association
    target ||= { rev_id: latest_revision, from_rev: nil, diff_mode: false }
    @rev_id = target[:rev_id]
    @from_rev = target[:from_rev]
    @diff_mode = target[:diff_mode]
    true
  end

  # The text to score, or nil when the URL could not be resolved.
  def extract_plain_text
    # If there is plain_text param, just return that
    return params[:plain_text] if params[:plain_text].present?
    # Get plain text from the url
    return unless parse_url

    GetRevisionPlaintext
      .new(@rev_id, @wiki, diff_mode: @diff_mode, from_rev: @from_rev)
      .plain_text
  end

  def latest_revision
    WikiApi::ArticleContent.new(@wiki).latest_revision_id(CGI.unescape(@article_title))
  end

  def create_revision_ai_scores_for_multiple_resources
    selected_detectors.each do |detector|
      next unless @results.key?(detector.key)

      create_revision_ai_score(detector, detector.parse(@results[detector.key]))
    end
  end

  # Imports data into the RevisionAiScores table
  def create_revision_ai_score(detector, parser)
    wiki_id = @wiki.id if @wiki
    RevisionAiScore.create(revision_id: @rev_id,
                           wiki_id:,
                           url: @url,
                           origin_user_id: current_user.id,
                           avg_ai_likelihood: parser.average_ai_likelihood,
                           max_ai_likelihood: parser.max_ai_likelihood,
                           details: parser.clean_result,
                           check_type: detector.key,
                           check_origin: RevisionAiScore::AI_TOOL_ORIGIN)
  end
end
