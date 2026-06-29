# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"

# Encapsulates MediaWiki API queries for article and revision content.
# Moves raw query logic into named methods to hide implementation details.
class WikiApi
  class ArticleContent
    def initialize(wiki, update_service: nil)
      @wiki = wiki
      @wiki_api = WikiApi.new(@wiki, update_service)
    end

    # ---- Revision Metadata ----

    # Returns the latest revision ID for the article +title+.
    def latest_revision_id(title)
      params = {
        action: 'query',
        prop: 'revisions',
        titles: title,
        rvprop: 'ids'
      }
      response = @wiki_api.query(params)
      page = response.data['pages']
      page_id = page.keys.first
      page.dig(page_id, 'revisions')&.first&.dig('revid')
    end

    # Returns the parent revision ID for a given +rev_id+.
    # Returns nil if the revision is missing or deleted.
    def parent_revision_id(rev_id)
      params = { prop: 'revisions', revids: rev_id, rvprop: 'ids' }
      resp = @wiki_api.query(params)

      if resp.data['badrevids'].present?
        Sentry.capture_message(
          "WikiApi::ArticleContent: revision #{rev_id} missing or deleted"
        )
        return nil
      end

      page_id = resp.data['pages'].keys.first
      resp.data.dig('pages', page_id, 'revisions')&.first&.dig('parentid')
    end

    # Returns parent revision IDs for a batch of +rev_ids+.
    # Used by RevisionScoreImporter.
    # Returns a hash { mw_rev_id => parent_id_string } or nil on failure.
    def parent_revision_ids(rev_ids)
      return {} if rev_ids.blank?
      params = { prop: 'revisions', revids: rev_ids, rvprop: 'ids' }
      response = @wiki_api.query(params)
      return unless response.present? && response.data['pages']

      revisions = {}
      response.data['pages'].each_value do |page_data|
        rev_data = page_data['revisions']
        next unless rev_data
        rev_data.each do |rev_datum|
          mw_rev_id = rev_datum['revid']
          parent_id = rev_datum['parentid']
          next if parent_id.zero?
          revisions[mw_rev_id] = parent_id.to_s
        end
      end
      revisions
    end

    # ---- Rendered HTML ----

    # Returns HTML rendering and metadata for a specific revision.
    # Returns a hash: { html:, title:, page_id: }
    def revision_html(rev_id)
      params = { oldid: rev_id }
      resp = api_client.send(:action, 'parse', params)
      {
        html: resp.data.dig('text', '*'),
        title: resp.data.dig('title'),
        page_id: resp.data.dig('pageid')
      }
    end

    # Parses raw wikitext into HTML string.
    def parse_wikitext(wikitext)
      params = { text: wikitext, contentmodel: 'wikitext' }
      resp = api_client.send(:action, 'parse', params)
      resp.data.dig('text', '*')
    end

    # ---- Diffs ----

    # Returns a diff table comparing two revisions.
    # Returns a hash: { diff_html:, title:, page_id: }
    # Returns nil if either revision's content has been suppressed/deleted
    # between scheduling and processing (compare raises missingcontent).
    def revision_diff(from_rev, to_rev)
      params = { torev: to_rev, fromrev: from_rev, difftype: 'table' }
      resp = api_client.send(:action, 'compare', params)
      {
        diff_html: resp.data['*'],
        title: resp.data.dig('totitle'),
        page_id: resp.data.dig('toid')
      }
    rescue MediawikiApi::ApiError => e
      raise unless e.code == 'missingcontent'
      Sentry.capture_message(
        "WikiApi::ArticleContent: revision content missing for diff " \
        "#{from_rev} -> #{to_rev}"
      )
      nil
    end

    # ---- Revision History ----

    # Fetches revision history for a page within a date range.
    # Handles continuation automatically.
    # If a block is given, stops fetching if the block returns truthy (early exit).
    # Returns all revisions fetched as a flat array.
    def revision_history(page_id, start_date:, end_date:, limit: 500, &block)
      query_params = revision_history_params(page_id, start_date, end_date, limit)
      fetch_all_revisions(page_id, query_params, &block)
    end

    # Returns true if the page was edited by any of the course students between
    # start_date and end_date.
    def course_edit_after?(page_id, course:, start_date:, end_date: nil)
      students = course.students.pluck(:username)
      end_date ||= course.end
      revisions = revision_history(page_id, start_date: end_date, end_date: start_date) do |batch|
        batch.any? { |rev| students.include?(rev['user']) }
      end
      revisions.any? { |rev| students.include?(rev['user']) }
    end

    private

    def revision_history_params(page_id, start_date, end_date, limit)
      {
        action: 'query',
        prop: 'revisions',
        pageids: page_id,
        rvprop: 'user',
        rvstart: start_date.strftime('%Y%m%d%H%M%S'),
        rvend: end_date.strftime('%Y%m%d%H%M%S'),
        rvdir: 'older',
        rvlimit: limit
      }
    end

    def fetch_all_revisions(page_id, query_params)
      all_revisions = []
      loop do
        response = @wiki_api.query(query_params)
        return all_revisions unless response

        revisions = response.data.dig('pages', page_id.to_s, 'revisions')
        if revisions.present?
          all_revisions.concat(revisions)
          break if block_given? && yield(revisions)
        end

        cont = response['continue']
        break unless cont
        query_params['rvcontinue'] = cont['rvcontinue']
      end

      all_revisions
    end

    def api_client
      @wiki_api.send(:api_client)
    end
  end
end
