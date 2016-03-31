require 'mediawiki_api'

#= Imports revision scoring data from ores.wmflabs.org
# Currently, this only applies to English Wikipedia.
# French Wikipedia also has a wp10 model for ores, but it that wiki has a different
# scale.
class RevisionScoreImporter
  ################
  # Entry points #
  ################
  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
  end

  def update_revision_scores(revisions=nil)
    revisions = if revisions
                  revisions.select { |rev| rev.wiki_id == @wiki.id }
                else
                  unscored_mainspace_userspace_and_draft_revisions
                end

    batches = revisions.count / 1000 + 1
    revisions.each_slice(1000).with_index do |rev_batch, i|
      Rails.logger.debug "Pulling revisions: batch #{i + 1} of #{batches}"
      get_and_save_scores rev_batch
    end
  end

  def update_all_revision_scores_for_articles(articles)
    page_ids = articles.map(&:mw_page_id)
    revisions = Revision.where(wiki_id: @wiki.id, mw_page_id: page_ids)
    update_revision_scores revisions

    first_revisions = []
    page_ids.each do |id|
      first_revisions << Revision.where(mw_page_id: id, wiki_id: @wiki.id).first
    end

    first_revisions.each { |revision| update_wp10_previous(revision) }
  end

  ##################
  # Helper methods #
  ##################
  private

  # This should take up to 50 rev_ids per batch
  def get_and_save_scores(rev_batch)
    scores = {}
    threads = rev_batch.in_groups_of(50, false).each_with_index.map do |fifty_revs, i|
      rev_ids = fifty_revs.map(&:mw_rev_id)
      Thread.new(i) do
        thread_scores = get_revision_scores rev_ids
        scores.merge!(thread_scores)
      end
    end
    threads.each(&:join)
    save_scores scores
  end

  def update_wp10_previous(revision)
    parent_id = get_parent_id revision
    score = get_revision_scores [parent_id]
    return unless score[parent_id.to_s].key?('probability')
    probability = score[parent_id.to_s]['probability']
    revision.wp10_previous = en_wiki_weighted_mean_score probability
    revision.save
  end

  def unscored_mainspace_userspace_and_draft_revisions
    Revision.joins(:article)
            .where(wp10: nil, wiki_id: @wiki.id)
            .where(articles: { namespace: [0, 2, 118] })
  end

  def save_scores(scores)
    scores.each do |rev_id, score|
      next unless score.key?('probability')
      revision = Revision.find_by(mw_rev_id: rev_id.to_i, wiki_id: @wiki.id)
      revision.wp10 = en_wiki_weighted_mean_score score['probability']
      revision.save
    end
  end

  def get_parent_id(revision)
    require "#{Rails.root}/lib/wiki_api"

    rev_id = revision.mw_rev_id
    rev_query = revision_query(rev_id)
    response = WikiApi.new(revision.wiki).query rev_query
    prev_id = response.data['pages'].values[0]['revisions'][0]['parentid']
    prev_id
  end

  def revision_query(rev_id)
    rev_query = { prop: 'revisions',
                  revids: rev_id,
                  rvprop: 'ids'
                }
    rev_query
  end

  def en_wiki_weighted_mean_score(probability)
    mean = probability['FA'] * 100
    mean += probability['GA'] * 80
    mean += probability['B'] * 60
    mean += probability['C'] * 40
    mean += probability['Start'] * 20
    mean += probability['Stub'] * 0
    mean
  end

  def query_url(rev_ids)
    base_url = 'https://ores.wmflabs.org/v1/scores/enwiki/wp10/?revids='
    rev_ids_param = rev_ids.map(&:to_s).join('|')
    url = base_url + rev_ids_param
    url = URI.encode url
    url
  end

  ###############
  # API methods #
  ###############
  def get_revision_scores(rev_ids)
    # TODO: i18n
    url = query_url(rev_ids)
    response = Net::HTTP.get(URI.parse(url))
    scores = JSON.parse(response)
    scores
  rescue StandardError => error
    raise error unless typical_errors.include?(error.class)
    return {}
  end

  def typical_errors
    [Errno::ETIMEDOUT,
     Net::ReadTimeout,
     Errno::ECONNREFUSED,
     JSON::ParserError,
     Errno::EHOSTUNREACH]
  end
end
