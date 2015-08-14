require 'mediawiki_api'

class RevisionScoreImporter
  ################
  # Entry points #
  ################
  def self.update_revision_scores(revisions=nil)
    # Unscored mainspace and userspace revisions, by default
    revisions ||= Revision.where(namespace: [0,2], wp10: nil)
    revisions.each_slice(50) do |rev_batch|
      rev_ids = rev_batch.map(&:id)
      scores = get_revision_scores rev_ids
      save_scores scores
    end
  end

  def self.update_all_revision_scores_for_articles(article_ids = nil)
    article_ids ||= Article.namespace(0).pluck(:id)
    revisions = Revision.where(article_id: article_ids)
    update_revision_scores revisions

    first_revisions = []
    article_ids.each do |id|
      first_revisions << Revision.where(article_id: id).first
    end

    first_revisions.each do |revision|
      parent_id = get_parent_id revision
      score = get_revision_scores [parent_id]
      probability = score[parent_id.to_s]['probability']
      revision.wp10_previous = weighted_mean_score probability
      revision.save
    end
  end

  ##################
  # Helper methods #
  ##################

  def self.save_scores(scores)
    scores.each do |rev_id, score|
      revision = Revision.find(rev_id.to_i)
      revision.wp10 = weighted_mean_score score['probability']
      revision.save
    end
  end

  def self.get_parent_id(revision)
    require "#{Rails.root}/lib/wiki"

    rev_id = revision.id
    rev_query = revision_query(rev_id)
    response = Wiki.query rev_query
    prev_id = response.data['pages'].values[0]['revisions'][0]['parentid']
    prev_id
  end

  def self.revision_query(rev_id)
    rev_query = { prop: 'revisions',
                  revids: rev_id,
                  rvprop: 'ids'
                }
    rev_query
  end

  def self.weighted_mean_score(probability)
    mean = probability['FA'] * 100
    mean += probability['GA'] * 80
    mean += probability['B'] * 60
    mean += probability['C'] * 40
    mean += probability['Start'] * 20
    mean += probability['Stub'] * 0
    mean
  end

  ###############
  # API methods #
  ###############
  def self.get_revision_scores(rev_ids)
    # TODO: i18n
    base_url = 'http://ores.wmflabs.org/scores/enwiki/wp10/?revids='
    rev_ids_param = rev_ids.map(&:to_s).join('|')
    url = base_url + rev_ids_param
    url = URI.encode url
    response = Net::HTTP.get(URI.parse(url))
    scores = JSON.parse(response)
    scores
  end
end
