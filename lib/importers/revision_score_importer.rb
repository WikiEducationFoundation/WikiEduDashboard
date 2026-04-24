# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/revision_score_api_handler"
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

#= Imports revision scoring data from Lift Wing and reference-counter APIs.
#= This class populates wp10, wp10_previous, features, features_previous and
#= deleted fields.
class RevisionScoreImporter
  BATCH_SIZE = 50

  ################
  # Entry points #
  ################
  def initialize(language: 'en', project: 'wikipedia', wiki: nil, course: nil, update_service: nil)
    @course = course
    @update_service = update_service
    @wiki = wiki || Wiki.get_or_create(language:, project:)
    @api_handler = RevisionScoreApiHandler.new(wiki: @wiki, update_service:)
  end

  # Takes an array of Revision records, and returns an array of Revisions records
  # with scores completed.
  def get_revision_scores(new_revisions)
    scores = {}
    parent_scores = {}
    parent_revisions = {}

    n_batches = calculate_number_of_batches(new_revisions.count)
    revision_batches = batch_revisions(new_revisions)
    revision_batches.each.with_index do |rev_batch, i|
      Rails.logger.debug { "Pulling revisions: batch #{i + 1} of #{n_batches}" }

      # Get scores for the given revision batch
      scores.merge!(@api_handler.get_revision_data(rev_batch.map(&:mw_rev_id)))

      # Get parent revisions
      my_parent_revisions = get_parent_revisions(rev_batch)
      next if my_parent_revisions.nil?
      parent_revisions.merge!(my_parent_revisions)

      # Get scores for the parent revision batch
      parent_scores.merge!(@api_handler.get_revision_data(my_parent_revisions.values.map(&:to_i)))
    end

    add_scores_to_revisions(revision_batches.flatten, parent_revisions, scores, parent_scores)
  end

  ##################
  # Helper methods #
  ##################
  private

  def calculate_number_of_batches(count)
    (count / BATCH_SIZE) + 1
  end

  def batch_revisions(revisions)
    revisions.each_slice(BATCH_SIZE).to_a
  end


  def get_parent_revisions(rev_batch)
    rev_ids = non_new_revisions(rev_batch)
    WikiApi::ArticleContent.new(@wiki, update_service: @update_service)
                           .parent_revision_ids(rev_ids)
  end

  def non_new_revisions(revisions)
    revisions.reject { |rev| rev.new_article == true }
             .map(&:mw_rev_id)
  end

  def add_scores_to_revisions(revisions, parent_revisions, scores, parent_scores)
    revisions.each do |rev|
      # add scores
      mw_rev_id_scores = scores[rev.mw_rev_id.to_s]
      update_scores(rev, mw_rev_id_scores) if mw_rev_id_scores

      # add previous scores
      next unless parent_revisions.key? rev.mw_rev_id.to_i # parent revisions hash has ids as keys
      parent_id = parent_revisions[rev.mw_rev_id.to_i]
      mw_rev_id_parent_scores = parent_scores[parent_id]
      update_previous_scores(rev, mw_rev_id_parent_scores) if mw_rev_id_parent_scores
    end

    revisions
  end

  def update_scores(rev, rev_scores)
    rev.features = rev_scores['features']
    rev.deleted = rev_scores['deleted'] # double check if this is a boolean
    rev.error = rev_scores['error']
  end

  def update_previous_scores(rev, parent_rev_scores)
    rev.features_previous = parent_rev_scores['features']
    # turn on error if there was an error fetching parent scores
    rev.error = true if parent_rev_scores['error']
  end

  class InvalidWikiError < StandardError; end
end
