require 'mediawiki_api'

#= Imports revision scoring data from ores.wmflabs.org
class RevisionScoreImporter
  def initialize(wiki)
    @wiki = wiki
  end

  ################
  # Entry points #
  ################
  def self.update_revision_scores(revisions=nil)
    # Unscored mainspace, userspace, and Draft revisions, by default
    revisions ||= unscored_mainspace_userspace_and_draft_revisions
    batch_no = 1
    batch_size = 1000
    batches = (revisions.count / batch_size) + 1
    # FIXME: double batching
    revisions.group_by(&:wiki).each do |wiki, local_revisions|
      Utils.chunk_requests(local_revisions, batch_size) do |rev_batch|
        Rails.logger.debug "Pulling revisions: batch #{batch_no} of #{batches}"
        new(wiki).get_and_save_scores rev_batch
        batch_no += 1
      end
    end
  end

  # This should take up to 50 rev_ids per batch
  def get_and_save_scores(rev_batch)
    scores = {}
    threads = rev_batch.in_groups_of(50, false).each_with_index.map do |fifty_revs, i|
      rev_ids = fifty_revs.map(&:id)
      Thread.new(i) do
        thread_scores = get_revision_scores rev_ids
        scores.merge!(thread_scores)
      end
    end
    threads.each(&:join)
    save_scores scores
  end

  # FIXME: Only used in a test?
  def update_all_revision_scores_for_articles(page_ids = nil)
    # TODO: group by wiki (pending above fixme)
    page_ids ||= Article.namespace(0).pluck(:native_id)
    revisions = Revision.where(page_id: page_ids)
    update_revision_scores revisions

    first_revisions = []
    page_ids.each do |page_id|
      first_revisions << Revision.where(page_id: page_id).first
    end

    first_revisions.each do |revision|
      parent_id = get_parent_id revision
      score = get_revision_scores [parent_id]
      next unless score[parent_id.to_s].key?('probability')
      probability = score[parent_id.to_s]['probability']
      revision.wp10_previous = weighted_mean_score probability
      revision.save
    end
  end

  ##################
  # Helper methods #
  ##################

  def unscored_mainspace_userspace_and_draft_revisions
    Revision.joins(:article)
      .where(wp10: nil)
      .where(wiki_id: @wiki.id)
      .where(articles: { namespace: [0, 2, 118] })
  end

  def save_scores(scores)
    scores.each do |rev_id, score|
      next unless score.key?('probability')
      revision = Revision.find_by(native_id: rev_id.to_i, wiki_id: @wiki.id)
      revision.wp10 = weighted_mean_score score['probability']
      revision.save
    end
  end

  def get_parent_id(revision)
    # FIXME: Why not autoloaded?
    require "#{Rails.root}/lib/wiki_api"

    rev_id = revision.native_id
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

  def weighted_mean_score(probability)
    mean = probability['FA'] * 100
    mean += probability['GA'] * 80
    mean += probability['B'] * 60
    mean += probability['C'] * 40
    mean += probability['Start'] * 20
    mean += probability['Stub'] * 0
    mean
  end

  def query_url(rev_ids)
    base_url = "http://ores.wmflabs.org/scores/#{@wiki.db_name}/wp10/?revids="
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
    typical_errors = [Errno::ETIMEDOUT,
                      Net::ReadTimeout,
                      Errno::ECONNREFUSED,
                      JSON::ParserError]
    raise error unless typical_errors.include?(error.class)
    return {}
  end
end
