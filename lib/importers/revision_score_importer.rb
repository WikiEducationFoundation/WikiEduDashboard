# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/ores_api"
require_dependency "#{Rails.root}/lib/wiki_api"

#= Imports revision scoring data from ores.wikimedia.org
class RevisionScoreImporter
  # All the wikis with an articlequality model as of 2018-09-18
  # https://ores.wikimedia.org/v3/scores/
  AVAILABLE_WIKIPEDIAS = %w[en eu fa fr ru simple tr].freeze
  ################
  # Entry points #
  ################
  def self.update_revision_scores_for_all_wikis
    AVAILABLE_WIKIPEDIAS.each do |language|
      new(language).update_revision_scores
    end
  end

  def initialize(language = 'en')
    validate_wiki(language)
    @wiki = Wiki.get_or_create(language: language, project: 'wikipedia')
    @ores_api = OresApi.new(@wiki)
  end

  # assumes a mediawiki rev_id from the correct Wikipedia
  def fetch_ores_data_for_revision_id(rev_id)
    ores_data = @ores_api.get_revision_data([rev_id])
    features = ores_data.dig(wiki_key, 'scores', rev_id.to_s, 'articlequality', 'features')
    rating = ores_data.dig(wiki_key, 'scores', rev_id.to_s, 'articlequality', 'score', 'prediction')
    return { features: features, rating: rating }
  end

  def update_revision_scores(revisions=nil)
    revisions = revisions&.select { |rev| rev.wiki_id == @wiki.id }
    revisions ||= unscored_mainspace_userspace_and_draft_revisions

    batches = revisions.count / OresApi::REVS_PER_REQUEST + 1
    revisions.each_slice(OresApi::REVS_PER_REQUEST).with_index do |rev_batch, i|
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
    batches = revisions.count / OresApi::REVS_PER_REQUEST + 1
    revisions.each_slice(OresApi::REVS_PER_REQUEST).with_index do |rev_batch, i|
      Rails.logger.debug "Getting wp10_previous: batch #{i + 1} of #{batches}"
      update_wp10_previous_batch rev_batch
    end
  end

  ##################
  # Helper methods #
  ##################
  private

  def validate_wiki(language)
    return if AVAILABLE_WIKIPEDIAS.include?(language)
    raise InvalidWikiError, language
  end

  # The top-level key representing the wiki in ORES data
  def wiki_key
    # This assumes the project is Wikipedia, which is true for all wikis with the articlequality
    # model as of 2018-09.
    @wiki_key ||= "#{@wiki.language}wiki"
  end

  # This should take up to OresApi::CONCURRENCY rev_ids per batch
  def get_and_save_scores(rev_batch)
    scores_data = @ores_api.get_revision_data rev_batch.map(&:mw_rev_id)
    scores = scores_data.dig(wiki_key, 'scores') || {}
    save_scores(scores)
  end

  def update_wp10_previous_batch(rev_batch)
    parent_revisions = get_parent_revisions(rev_batch)
    return unless parent_revisions&.any?
    parent_quality_data = @ores_api.get_revision_data parent_revisions.values
    scores = parent_quality_data.dig(wiki_key, 'scores') || {}
    save_parent_scores(parent_revisions, scores)
  end

  def save_parent_scores(parent_revisions, scores)
    parent_revisions.each do |mw_rev_id, parent_id|
      next unless scores.key? parent_id
      article_completeness = weighted_mean_score(scores[parent_id])
      Revision.find_by(mw_rev_id: mw_rev_id.to_i, wiki: @wiki)
              .update(wp10_previous: article_completeness)
    end
  end

  def unscored_mainspace_userspace_and_draft_revisions
    Revision.joins(:article)
            .where(wp10: nil, wiki_id: @wiki.id, deleted: false)
            .where(articles: { namespace: [0, 2, 118] })
  end

  def save_scores(scores)
    scores.each do |mw_rev_id, score|
      revision = Revision.find_by(mw_rev_id: mw_rev_id.to_i, wiki_id: @wiki.id)
      revision.wp10 = weighted_mean_score(score)
      revision.features = score.dig('articlequality', 'features')
      revision.deleted = true if deleted?(score)
      revision.save
    end
  end

  def get_parent_revisions(rev_batch)
    revisions = {}
    rev_query = parent_revisions_query rev_batch.map(&:mw_rev_id)
    response = WikiApi.new(@wiki).query rev_query
    return unless response.data['pages']
    response.data['pages'].each do |_page_id, page_data|
      rev_data = page_data['revisions']
      next unless rev_data
      rev_data.each do |rev_datum|
        mw_rev_id = rev_datum['revid']
        parent_id = rev_datum['parentid']
        next if parent_id.zero? # parentid 0 means there is no parent.
        revisions[mw_rev_id] = parent_id.to_s
      end
    end

    revisions
  end

  def parent_revisions_query(rev_ids)
    { prop: 'revisions',
      revids: rev_ids,
      rvprop: 'ids' }
  end

  # ORES articlequality ratings are often derived from the en.wiki system,
  # so this is the fallback scheme.
  ENWIKI_WEIGHTING = { 'FA'    => 100,
                       'GA'    => 80,
                       'B'     => 60,
                       'C'     => 40,
                       'Start' => 20,
                       'Stub'  => 0 }.freeze
  FRWIKI_WEIGHTING = { 'adq' => 100,
                       'ba' => 80,
                       'a' => 60,
                       'b' => 40,
                       'bd' => 20,
                       'e' => 0 }.freeze
  TRWIKI_WEIGHTING = { 'sm' => 100,
                       'km' => 80,
                       'b' => 60,
                       'c' => 40,
                       'baslagıç' => 20,
                       'taslak' => 0 }.freeze
  RUWIKI_WEIGHTING = { 'ИС' => 100,
                       'ДС' => 80,
                       'ХС' => 80,
                       'I' => 60,
                       'II' => 40,
                       'III' => 20,
                       'IV' => 0 }.freeze
  WEIGHTING_BY_LANGUAGE = {
    'en' => ENWIKI_WEIGHTING,
    'simple' => ENWIKI_WEIGHTING,
    'fa' => ENWIKI_WEIGHTING,
    'eu' => ENWIKI_WEIGHTING,
    'fr' => FRWIKI_WEIGHTING,
    'tr' => TRWIKI_WEIGHTING,
    'ru' => RUWIKI_WEIGHTING
  }.freeze

  def weighting
    @weighting ||= WEIGHTING_BY_LANGUAGE[@wiki.language]
  end

  def weighted_mean_score(score)
    probability = score&.dig('articlequality', 'score', 'probability')
    return unless probability
    mean = 0
    weighting.each do |rating, weight|
      mean += probability[rating] * weight
    end
    mean
  end

  DELETED_REVISION_ERRORS = %w[TextDeleted RevisionNotFound].freeze
  def deleted?(score)
    DELETED_REVISION_ERRORS.include? score.dig('articlequality', 'error', 'type')
  end

  class InvalidWikiError < StandardError; end
end
