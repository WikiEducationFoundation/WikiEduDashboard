# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"
require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"

class AiToolsController < ApplicationController
  before_action :require_admin_permissions

  def show; end

  def compare_pangrams
    parse_url
    @diff_mode = params[:diff_mode] == 'true'
    @plain = GetRevisionPlaintext.new(@rev_id, @wiki, diff_mode: @diff_mode, from_rev: @from_rev)
    @pangram_v2_result = PangramApi.v2.inference @plain.plain_text
    @pangram_v3_result = PangramApi.v3.inference @plain.plain_text

    render 'show'
  end

  private

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
