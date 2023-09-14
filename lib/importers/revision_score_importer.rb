# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/lift_wing_api"
require_dependency "#{Rails.root}/lib/wiki_api"

#= Imports revision scoring data from Lift Wing
class RevisionScoreImporter
  BATCH_SIZE = 50

  ################
  # Entry points #
  ################
  def self.update_revision_scores_for_all_wikis
    LiftWingApi::AVAILABLE_WIKIPEDIAS.each do |language|
      new(language:).update_revision_scores
      new(language:).update_previous_revision_scores
    end

    new(language: nil, project: 'wikidata').update_revision_scores
    new(language: nil, project: 'wikidata').update_previous_revision_scores
  end

  def self.update_revision_scores_for_course(course, update_service: nil)
    course.wikis.each do |wiki|
      next unless LiftWingApi.valid_wiki?(wiki)
      new(wiki:, course:, update_service:)
        .update_revision_scores
      new(wiki:, course:, update_service:)
        .update_previous_revision_scores
    end
  end

  def initialize(language: 'en', project: 'wikipedia', wiki: nil, course: nil, update_service: nil)
    @course = course
    @update_service = update_service
    @wiki = wiki || Wiki.get_or_create(language:, project:)
    @lift_wing_api = LiftWingApi.new(@wiki, @update_service)
  end

  # assumes a mediawiki rev_id from the correct Wikipedia
  def fetch_ores_data_for_revision_id(rev_id)
    articlequality_data = @lift_wing_api.get_revision_data([rev_id])
    features = articlequality_data.dig(wiki_key, 'scores', rev_id.to_s, model_key, 'features')
    rating = articlequality_data.dig(wiki_key, 'scores', rev_id.to_s, model_key, 'score', 'prediction')
    return { features:, rating: }
  end

  def update_revision_scores
    batches = (unscored_revisions.count / BATCH_SIZE) + 1
    unscored_revisions.in_batches(of: BATCH_SIZE).each.with_index do |rev_batch, i|
      Rails.logger.debug { "Pulling revisions: batch #{i + 1} of #{batches}" }
      get_and_save_scores rev_batch
    end
  end

  def update_previous_revision_scores
    batches = (unscored_previous_revisions.count / BATCH_SIZE) + 1
    unscored_previous_revisions
      .in_batches(of: BATCH_SIZE)
      .each.with_index do |rev_batch, i|
      Rails.logger.debug { "Getting wp10_previous: batch #{i + 1} of #{batches}" }
      get_and_save_previous_scores rev_batch
    end
  end

  ##################
  # Helper methods #
  ##################
  private

  # The top-level key representing the wiki in LiftWing data
  def wiki_key
    # This assumes the project is Wikipedia, which is true for all wikis with the articlequality
    # or the language is nil, which is the case for Wikidata.
    @wiki_key ||= "#{@wiki.language || @wiki.project}wiki"
  end

  def model_key
    @model_key ||= @wiki.project == 'wikidata' ? 'itemquality' : 'articlequality'
  end

  def get_and_save_scores(rev_batch)
    scores_data = @lift_wing_api.get_revision_data rev_batch.map(&:mw_rev_id)
    scores = scores_data.dig(wiki_key, 'scores') || {}
    save_scores(scores)
  end

  def get_and_save_previous_scores(rev_batch)
    parent_revisions = get_parent_revisions(rev_batch)
    return unless parent_revisions&.any?
    parent_quality_data = @lift_wing_api.get_revision_data parent_revisions.values.map(&:to_i)
    scores = parent_quality_data.dig(wiki_key, 'scores') || {}
    save_parent_scores(parent_revisions, scores)
  end

  def save_parent_scores(parent_revisions, scores)
    parent_revisions.each do |mw_rev_id, parent_id|
      next unless scores.key? parent_id
      article_completeness = weighted_mean_score(scores[parent_id])
      features_previous = scores[parent_id]&.dig(model_key, 'features')
      Revision.find_by(mw_rev_id: mw_rev_id.to_i, wiki: @wiki)
              .update(wp10_previous: article_completeness, features_previous:)
    end
  end

  def mainspace_userspace_and_draft_revisions
    all_revisions = @course&.revisions || Revision
    all_revisions.joins(:article)
                 .where(wiki_id: @wiki.id, deleted: false)
                 .where(articles: { namespace: [0, 2, 118] })
  end

  def unscored_revisions
    mainspace_userspace_and_draft_revisions.where(features: nil)
  end

  def unscored_previous_revisions
    mainspace_userspace_and_draft_revisions.where(features_previous: nil, new_article: false)
  end

  def save_scores(scores)
    scores.each do |mw_rev_id, score|
      revision = Revision.find_by(mw_rev_id: mw_rev_id.to_i, wiki_id: @wiki.id)
      next unless revision
      revision.wp10 = weighted_mean_score(score)
      revision.features = score.dig(model_key, 'features')
      revision.deleted = true if deleted?(score)
      revision.save
    end
  end

  def get_parent_revisions(rev_batch)
    rev_query = parent_revisions_query rev_batch.map(&:mw_rev_id)
    response = WikiApi.new(@wiki, @update_service).query rev_query
    return unless response.present? && response.data['pages']
    extract_revisions(response.data['pages'])
  end

  def extract_revisions(pages_data)
    revisions = {}
    pages_data.each do |_page_id, page_data|
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
  PTWIKI_WEIGHTING = { '6' => 100,
                       '5' => 80,
                       '4' => 60,
                       '3' => 40,
                       '2' => 20,
                       '1' => 0 }.freeze
  UKWIKI_WEIGHTING = { 'ДС' => 100,
                       'ВС' => 80,
                       'I' => 60,
                       'II' => 40,
                       'III' => 20,
                       'IV' => 0 }.freeze
  # SV wiki has three high ratings, all of which are rare:
  # This is just a guess at appropriate weighting for the case where almost
  # all articles are the lowest tier.
  SVWIKI_WEIGHTING = { 'u' => 100,
                       'b' => 90,
                       'r' => 80,
                       's' => 0 }.freeze
  NLWIKI_WEIGHTING = { 'A' => 100,
                       'B' => 75,
                       'C' => 50,
                       'D' => 25,
                       'E' => 0 }.freeze
  WEIGHTING_BY_LANGUAGE = {
    'en' => ENWIKI_WEIGHTING,
    'simple' => ENWIKI_WEIGHTING,
    'fa' => ENWIKI_WEIGHTING,
    'eu' => ENWIKI_WEIGHTING,
    'fr' => FRWIKI_WEIGHTING,
    'tr' => TRWIKI_WEIGHTING,
    'ru' => RUWIKI_WEIGHTING,
    'uk' => UKWIKI_WEIGHTING,
    'gl' => ENWIKI_WEIGHTING,
    'sv' => SVWIKI_WEIGHTING,
    'nl' => NLWIKI_WEIGHTING,
    'pt' => PTWIKI_WEIGHTING
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

  def deleted?(score)
    LiftWingApi::DELETED_REVISION_ERRORS.include? score.dig(model_key, 'error', 'type')
  end

  class InvalidWikiError < StandardError; end
end
