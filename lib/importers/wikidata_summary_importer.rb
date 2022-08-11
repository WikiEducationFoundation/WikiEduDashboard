# frozen_string_literal: true

class WikidataSummaryImporter
  def self.import_all_missing_summaries
    import_missing_summaries Revision.where(wiki: wikidata, summary: nil, deleted: false)
  end

  def self.import_missing_summaries(revisions)
    revisions.find_in_batches(batch_size: 50) do |revision_batch|
      summaries = fetch_summaries(revision_batch)

      revision_batch.each do |rev|
        summary = summaries[rev.mw_rev_id]
        next if summary.nil?

        rev.update(summary: CGI.escape(summary))
      end
    end
  end

  def self.wikidata
    @wikidata ||= Wiki.get_or_create(language: nil, project: 'wikidata')
  end

  def self.fetch_summaries(revisions)
    revids = revisions.map(&:mw_rev_id).join('|')
    query = {
      prop: 'revisions',
      rvprop: 'comment|ids',
      revids:
    }
    data = WikiApi.new(wikidata).query(query)
    page_data = data.data['pages']
    # Deleted revisions return data without a 'pages' key, like:
    # {"batchcomplete":"","query":{"badrevids":{"968242606":{"revid":968242606}}}}
    return {} unless page_data

    revision_data = {}
    page_data.each_value do |page|
      page['revisions'].each do |revision|
        revision_data[revision['revid']] = revision['comment']
      end
    end

    return revision_data
  end
end
