# frozen_string_literal: true

require "#{Rails.root}/lib/ores_api"
require "#{Rails.root}/lib/wiki_api"

#= Imports revision scoring data from ores.wikimedia.org
# As of July 2016, this only applies to English Wikipedia.
# French and other Wikipedias also have wp10 models for ORES, they don't match
# enwiki version.
class RevisionScoreImporter
  ################
  # Entry points #
  ################
  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    @ores_api = OresApi.new(@wiki)
  end

  # assumes a mediawiki rev_id from English Wikipedia
  def fetch_ores_data_for_revision_id(rev_id)
    ores_data = @ores_api.get_revision_data(rev_id)
    features = extract_features(ores_data)[rev_id.to_s]
    scores = extract_score(ores_data)
    rating = scores.dig(rev_id.to_s, 'prediction') unless scores.nil?
    return { features: features, rating: rating }
  end

  def update_revision_scores(revisions=nil)
    revisions = revisions&.select { |rev| rev.wiki_id == @wiki.id }
    revisions ||= unscored_mainspace_userspace_and_draft_revisions

    batches = revisions.count / OresApi::CONCURRENCY + 1
    revisions.each_slice(OresApi::CONCURRENCY).with_index do |rev_batch, i|
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

    update_previous_wp10_scores(first_revisions)
  end

  def update_previous_wp10_scores(revisions)
    batches = revisions.count / OresApi::CONCURRENCY + 1
    revisions.each_slice(OresApi::CONCURRENCY).with_index do |rev_batch, i|
      Rails.logger.debug "Getting wp10_previous: batch #{i + 1} of #{batches}"
      update_wp10_previous_batch rev_batch
    end
  end

  ##################
  # Helper methods #
  ##################
  private

  # This should take up to OresApi::CONCURRENCY rev_ids per batch
  def get_and_save_scores(rev_batch)
    scores, features = {}, {}
    threads = rev_batch.each_with_index.map do |revision, i|
      Thread.new(i) do
        ores_data = @ores_api.get_revision_data(revision.mw_rev_id)
        scores.merge!(extract_score(ores_data))
        features.merge!(extract_features(ores_data))
      end
    end
    threads.each(&:join)
    save_scores(scores, features)
  end

  def update_wp10_previous_batch(rev_batch)
    wp10_previous_scores = {}
    threads = rev_batch.each_with_index.map do |revision, i|
      Thread.new(i) do
        wp10_previous_scores[revision.id] = wp10_previous(revision)
      end
    end
    threads.each(&:join)
    save_wp10_previous(wp10_previous_scores)
  end

  def wp10_previous(revision)
    parent_id = get_parent_id revision
    return unless parent_id
    ores_data = @ores_api.get_revision_data(parent_id)
    score = extract_score ores_data
    return unless score[parent_id.to_s]&.key?('probability')
    probability = score[parent_id.to_s]['probability']
    en_wiki_weighted_mean_score(probability)
  end

  def unscored_mainspace_userspace_and_draft_revisions
    Revision.joins(:article)
            .where(wp10: nil, wiki_id: @wiki.id, deleted: false)
            .where(articles: { namespace: [0, 2, 118] })
  end

  DELETED_REVISION_ERRORS = %w[TextDeleted RevisionNotFound].freeze
  def save_scores(scores, features)
    scores.each do |mw_rev_id, score|
      revision = Revision.find_by(mw_rev_id: mw_rev_id.to_i, wiki_id: @wiki.id)
      revision.wp10 = en_wiki_weighted_mean_score score['probability']
      revision.features = features[mw_rev_id]
      revision.deleted = true if DELETED_REVISION_ERRORS.include? score.dig('error', 'type')
      revision.save
    end
  end

  def save_wp10_previous(scores)
    scores.each do |rev_id, wp10_prev|
      Revision.find(rev_id).update(wp10_previous: wp10_prev)
    end
  end

  def get_parent_id(revision)
    rev_id = revision.mw_rev_id
    rev_query = parent_revision_query(rev_id)
    response = WikiApi.new(@wiki).query rev_query
    return unless response.data['pages']
    prev_id = response.data['pages'].values[0]['revisions'][0]['parentid']
    prev_id
  end

  def parent_revision_query(rev_id)
    { prop: 'revisions',
      revids: rev_id,
      rvprop: 'ids' }
  end

  WP10_WEIGHTING = { 'FA'    => 100,
                     'GA'    => 80,
                     'B'     => 60,
                     'C'     => 40,
                     'Start' => 20,
                     'Stub'  => 0 }.freeze
  def en_wiki_weighted_mean_score(probability)
    return unless probability
    mean = 0
    WP10_WEIGHTING.each do |rating, weight|
      mean += probability[rating] * weight
    end
    mean
  end

  def extract_score(ores_data)
    return ores_data if ores_data.blank?
    scores = ores_data.dig('scores', 'enwiki', 'wp10', 'scores')
    scores || {}
  end

  def extract_features(ores_data)
    return ores_data if ores_data.blank?
    features = ores_data.dig('scores', 'enwiki', 'wp10', 'features')
    features || {}
  end
end
