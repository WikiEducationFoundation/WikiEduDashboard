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
    result = @lift_wing_api.get_single_revision_parsed_data(rev_id)
    features = result.dig('features')
    rating = result.dig('prediction')
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

  def model_key
    @model_key ||= @wiki.project == 'wikidata' ? 'itemquality' : 'articlequality'
  end

  def get_and_save_scores(rev_batch)
    rev_batch.each do |rev|
      result = @lift_wing_api.get_single_revision_parsed_data(rev.mw_rev_id)
      save_score(rev.mw_rev_id, result)
    end
  end

  def get_and_save_previous_scores(rev_batch)
    parent_revisions = get_parent_revisions(rev_batch)
    return unless parent_revisions&.any?
    parent_revisions.each do |rev_id, parent_id|
      parent_score = @lift_wing_api.get_single_revision_parsed_data(parent_id)
      save_parent_score(rev_id, parent_score)
    end
  end

  def save_parent_score(rev_id, parent_score)
    return unless parent_score
    Revision.find_by(mw_rev_id: rev_id.to_i, wiki: @wiki)
            .update(wp10_previous: parent_score.dig('wp10'),
                    features_previous: parent_score.dig('features'))
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

  def save_score(rev_id, score)
    revision = Revision.find_by(mw_rev_id: rev_id.to_i, wiki_id: @wiki.id)
    return unless revision
    revision.wp10 = score.dig('wp10')
    revision.features = score.dig('features')
    revision.deleted = score.dig('deleted')
    revision.save
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

  class InvalidWikiError < StandardError; end
end
