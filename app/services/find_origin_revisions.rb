# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wikiwho_api"
require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/ai/wikiwho_passage_attributor"
require_dependency "#{Rails.root}/lib/ai/history_passage_attributor"

# Finds the revisions that added passages of text already present in a
# revision of a page. Wikipedia mainspace articles use WikiWho's token-level
# authorship; other pages, and articles WikiWho cannot answer for, fall back
# to searching the page history.
class FindOriginRevisions
  # Each origin is { rev_id:, username:, timestamp:, words: }, most words first.
  attr_reader :origins

  # passages: normalized plain text paragraphs present in rev_id
  def initialize(wiki:, article:, rev_id:, passages:)
    @wiki = wiki
    @article = article
    @rev_id = rev_id
    @passages = passages
    @wiki_api = WikiApi.new(@wiki)
    @origins = []
    find_origins
  end

  private

  def find_origins
    return if @passages.empty?

    counts = wikiwho_word_counts.presence || history_word_counts
    return if counts.blank?

    @origins = counts.keys.each_slice(50).flat_map { |ids| revisions_info(ids) }
                     .map { |info| origin(info, counts) }
                     .sort_by { |origin| -origin[:words] }
  end

  def origin(info, counts)
    { rev_id: info['revid'], username: info['user'],
      timestamp: Time.zone.parse(info['timestamp']), words: counts[info['revid']] }
  end

  def wikiwho_word_counts
    return unless @wiki.project == 'wikipedia' && @article.namespace == Article::Namespaces::MAINSPACE

    tokens = WikiWhoApi.new(@wiki).rev_content(@rev_id)
    return if tokens.nil?

    WikiWhoPassageAttributor.new(passages: @passages, tokens:).word_counts
  end

  def history_word_counts
    response = @wiki_api.query(prop: 'revisions', pageids: @article.mw_page_id, rvstartid: @rev_id,
                               rvdir: 'older', rvprop: 'ids', rvlimit: 500)
    revisions = response&.data&.dig('pages', @article.mw_page_id.to_s, 'revisions')
    return if revisions.blank?

    # Without a continuation, the history reaches back to the page's first revision.
    HistoryPassageAttributor.new(passages: @passages, revisions:,
                                 complete: response['continue'].nil?, wiki: @wiki).word_counts
  end

  def revisions_info(rev_ids)
    response = @wiki_api.query(prop: 'revisions', revids: rev_ids.join('|'),
                               rvprop: 'ids|user|timestamp')
    pages = response&.data&.dig('pages') || {}
    pages.values.flat_map { |page| page['revisions'] || [] }
  end
end
