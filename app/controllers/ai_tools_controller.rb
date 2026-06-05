# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"
require_dependency "#{Rails.root}/lib/originality_api"
require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"
require_dependency "#{Rails.root}/lib/ai/pangram_response_parser"
require_dependency "#{Rails.root}/lib/ai/originality_response_parser"
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

class AiToolsController < ApplicationController
  before_action :require_admin_permissions

  def show; end

  def compare_ai_detectors
    detect_ai_from_multiple_resources extract_plain_text
    create_revision_ai_scores_for_multiple_resources
    render 'show'
  end

  private

  MAX_CONCURRENCY = 5

  DETECTORS = {
    RevisionAiScore::PANGRAM_V3_KEY => PangramApi.v3,
    RevisionAiScore::ORIGINALITY_TURBO_KEY => OriginalityApi.turbo,
    RevisionAiScore::ORIGINALITY_ACADEMIC_KEY => OriginalityApi.academic,
    RevisionAiScore::ORIGINALITY_LITE_KEY => OriginalityApi.lite,
    RevisionAiScore::ORIGINALITY_LITE_BETA_KEY => OriginalityApi.lite_beta
  }.freeze

  def detect_ai_from_multiple_resources(text)
    pool = Concurrent::FixedThreadPool.new(MAX_CONCURRENCY)
    @results = Concurrent::Hash.new

    DETECTORS.each do |key, detector|
      pool.post { detect_ai(key, detector, text) } if params[key.to_sym]
    end
    pool.shutdown && pool.wait_for_termination

    @pangram_v3_result = @results[RevisionAiScore::PANGRAM_V3_KEY]
    @originality_turbo_result = @results[RevisionAiScore::ORIGINALITY_TURBO_KEY]
    @originality_academic_result = @results[RevisionAiScore::ORIGINALITY_ACADEMIC_KEY]
    @originality_lite_result = @results[RevisionAiScore::ORIGINALITY_LITE_KEY]
    @originality_lite_beta_result = @results[RevisionAiScore::ORIGINALITY_LITE_BETA_KEY]
  end

  def detect_ai(key, ai_detector, text)
    @results[key] = ai_detector.inference text
  end

  def parse_url
    @url = params[:article_or_diff_url]
    parser = WikiUrlParser.new(@url)
    @wiki = parser.wiki
    @article_title = parser.title

    if parser.diff
      revs = [parser.oldid, parser.diff].compact
      @rev_id = revs.max
      @from_rev = revs.min if revs.count == 2
      @diff_mode = true
    else
      # If there is no diff revision in the url, it means it's just a single revision url.
      @diff_mode = false
      # If it does not contain an oldid either we have to manually fetch the latest revision.
      # Example: https://en.wikipedia.org/wiki/Greater_Cooch_Behar_People%27s_Association
      @rev_id = parser.oldid || latest_revision
    end
  end

  def extract_plain_text
    # If there is plain_text param, just return that
    return params[:plain_text] if params[:plain_text].present?
    # Get plain text from the url
    parse_url
    GetRevisionPlaintext
      .new(@rev_id, @wiki, diff_mode: @diff_mode, from_rev: @from_rev)
      .plain_text
  end

  def latest_revision
    WikiApi::ArticleContent.new(@wiki).latest_revision_id(CGI.unescape(@article_title))
  end

  def create_revision_ai_scores_for_multiple_resources
    RevisionAiScore::PANGRAM_KEYS.each do |key|
      next unless params[key.to_sym]
      parser = PangramResponseParser.new(key, @results[key])
      create_revision_ai_score(key, parser)
    end

    RevisionAiScore::ORIGINALITY_KEYS.each do |key|
      next unless params[key.to_sym]
      parser = OriginalityResponseParser.new(key, @results[key])
      create_revision_ai_score(key, parser)
    end
  end

  # Imports data into the RevisionAiScores table
  def create_revision_ai_score(check_type, parser)
    wiki_id = @wiki.id if @wiki
    RevisionAiScore.create(revision_id: @rev_id,
                           wiki_id:,
                           url: @url,
                           origin_user_id: current_user.id,
                           avg_ai_likelihood: parser.average_ai_likelihood,
                           max_ai_likelihood: parser.max_ai_likelihood,
                           details: parser.clean_result,
                           check_type:,
                           check_origin: RevisionAiScore::AI_TOOL_ORIGIN)
  end
end
