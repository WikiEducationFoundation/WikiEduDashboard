# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"
require_dependency "#{Rails.root}/lib/originality_api"
require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"

class AiToolsController < ApplicationController
  before_action :require_admin_permissions

  def show; end

  def compare_pangrams
    parse_url
    @diff_mode = params[:diff_mode] == 'true'
    @plain = GetRevisionPlaintext.new(@rev_id, @wiki, diff_mode: @diff_mode, from_rev: @from_rev)
    detect_ai_from_multiple_resources @plain.plain_text
    render 'show'
  end

  PANGRAM_V2_KEY = 'pangram_v2'
  PANGRAM_V3_KEY = 'pangram_v3'
  ORIGINALITY_TURBO_KEY = 'originality_turbo'
  ORIGINALITY_ACADEMIC_KEY = 'originality_academic'

  MODELS_KEY = [
    PANGRAM_V2_KEY,
    PANGRAM_V3_KEY,
    ORIGINALITY_TURBO_KEY,
    ORIGINALITY_ACADEMIC_KEY
  ].freeze

  private

  MAX_CONCURRENCY = 4

  DETECTORS = {
    PANGRAM_V2_KEY => PangramApi.v2,
    PANGRAM_V3_KEY => PangramApi.v3,
    ORIGINALITY_TURBO_KEY => OriginalityApi.turbo,
    ORIGINALITY_ACADEMIC_KEY => OriginalityApi.academic
  }.freeze

  def detect_ai_from_multiple_resources(text)
    pool = Concurrent::FixedThreadPool.new(MAX_CONCURRENCY)
    results = Concurrent::Hash.new

    DETECTORS.each do |key, detector|
      pool.post { detect_ai(key, detector, text, results) } if params[key.to_sym]
    end
    pool.shutdown && pool.wait_for_termination

    @pangram_v2_result = results[PANGRAM_V2_KEY]
    @pangram_v3_result = results[PANGRAM_V3_KEY]
    @originality_turbo_result = results[ORIGINALITY_TURBO_KEY]
    @originality_academic_result = results[ORIGINALITY_ACADEMIC_KEY]
  end

  def detect_ai(key, ai_detector, text, results)
    results[key] = ai_detector.inference text
  end

  def parse_url
    @url = params[:article_or_diff_url]
    parser = WikiUrlParser.new(@url)
    @wiki = parser.wiki
    @article_title= parser.title
    revs = [parser.oldid, parser.diff].compact
    @rev_id = revs.max
    @from_rev = revs.min if revs.count == 2
  end
end
