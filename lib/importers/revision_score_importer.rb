# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/revision_score_api_handler"
require_dependency "#{Rails.root}/lib/wiki_api"

#= Imports revision scoring data from Lift Wing and reference-counter APIs.
#= This class populates wp10, wp10_previous, features, features_previous and
#= deleted fields.
class RevisionScoreImporter
  BATCH_SIZE = 50

  ################
  # Entry points #
  ################
  def self.update_revision_scores_for_course(course, update_service: nil)
    course.wikis.each do |wiki|
      importer = new(wiki:, course:, update_service:)
      importer.update_revision_scores
      importer.update_previous_revision_scores
    end
  end

  def initialize(language: 'en', project: 'wikipedia', wiki: nil, course: nil, update_service: nil)
    @course = course
    @update_service = update_service
    @wiki = wiki || Wiki.get_or_create(language:, project:)
    @api_handler = RevisionScoreApiHandler.new(wiki: @wiki, update_service:)
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

  def get_revision_scores(new_revisions)
    scores = {}
    parent_scores = {}
    parent_revisions = {}

    n_batches = (new_revisions.count / BATCH_SIZE) + 1
    revision_batches = new_revisions.each_slice(BATCH_SIZE).to_a
    revision_batches.each.with_index do |rev_batch, i|
      Rails.logger.debug { "Pulling revisions: batch #{i + 1} of #{n_batches}" }
      scores.merge!(@api_handler.get_revision_data(rev_batch.map(&:mw_rev_id)))

      my_parent_revisions = get_parent_revisions(rev_batch)
      parent_revisions.merge!(my_parent_revisions)
      parent_scores.merge!(@api_handler.get_revision_data(my_parent_revisions.values.map(&:to_i)))
    end

    add_scores_to_revisions(revision_batches.flatten, parent_revisions, scores, parent_scores)
  end

  ##################
  # Helper methods #
  ##################
  private

  def get_and_save_scores(rev_batch)
    scores = @api_handler.get_revision_data rev_batch.map(&:mw_rev_id)
    save_scores(scores)
  end

  def get_and_save_previous_scores(rev_batch)
    parent_revisions = get_parent_revisions(rev_batch)
    return unless parent_revisions&.any?

    scores = @api_handler.get_revision_data parent_revisions.values.map(&:to_i)
    save_parent_scores(parent_revisions, scores)
  end

  def save_scores(scores)
    scores.each do |mw_rev_id, score|
      revision = Revision.find_by(mw_rev_id: mw_rev_id.to_i, wiki_id: @wiki.id)
      next unless revision
      revision.wp10 = score.dig('wp10')
      revision.features = score.dig('features')
      # only modify the existing deleted value if revision was deleted
      revision.deleted = true if score.dig('deleted')
      revision.save
    end
  end

  def save_parent_scores(parent_revisions, scores)
    parent_revisions.each do |mw_rev_id, parent_id|
      next unless scores.key? parent_id
      wp10_previous = scores.dig(parent_id, 'wp10')
      features_previous = scores.dig(parent_id, 'features')
      Revision.find_by(mw_rev_id: mw_rev_id.to_i, wiki: @wiki)
              .update(wp10_previous:, features_previous:)
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

  def add_scores_to_revisions(revisions, parent_revisions, scores, parent_scores)
    revisions.each do |rev|
      # add scores
      mw_rev_id_scores = scores[rev.mw_rev_id.to_s]
      update_scores(rev, mw_rev_id_scores)

      # add previous scores
      next unless parent_revisions.key? rev.mw_rev_id.to_i # parent revisions hash has ids as keys
      parent_id = parent_revisions[rev.mw_rev_id.to_i]
      mw_rev_id_parent_scores = parent_scores[parent_id]
      update_previous_scores(rev, mw_rev_id_parent_scores)
    end

    revisions
  end

  def update_scores(rev, rev_scores)
    rev.features = rev_scores['features']
    rev.wp10 = rev_scores['wp10']
    rev.deleted = rev_scores['deleted'] # double check if this is a boolean
  end

  def update_previous_scores(rev, parent_rev_scores)
    rev.wp10_previous = parent_rev_scores['wp10']
    rev.features_previous = parent_rev_scores['features']
  end

  class InvalidWikiError < StandardError; end
end
