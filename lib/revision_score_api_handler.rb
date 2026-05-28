# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/reference_counter_api"

#= Handles the logic to decide how to retrieve revision data for a given wiki.
# Determines whether the wiki is supported by the reference-counter API
# (e.g. en.wikipedia, es.wikipedia).
class RevisionScoreApiHandler
  def initialize(language: 'en', project: 'wikipedia', wiki: nil, update_service: nil)
    @update_service = update_service
    @wiki = wiki || Wiki.get_or_create(language:, project:)
    # Initialize ReferenceCounterApi if the wiki is valid for it
    return unless ReferenceCounterApi.valid_wiki?(@wiki)
    @reference_counter_api = ReferenceCounterApi.new(@wiki, @update_service)
  end

  # Returns data from the reference-counter API.
  # The response has the following format:
  # { "rev_0"=>
  #     { "features"=> { "num_ref"=>0 },
  #       "deleted"=>false,
  #       "error"=>false },
  #   ...,
  #   "rev_n"=>
  #     { "features"=> {},
  #       "deleted"=>false,
  #       "error"=>false }
  # }
  def get_revision_data(rev_batch)
    scores = maybe_get_reference_data(rev_batch)
    ensure_complete_scores scores
  end

  ##################
  # Helper methods #
  ##################
  private

  def maybe_get_reference_data(rev_batch)
    if ReferenceCounterApi.valid_wiki?(@wiki)
      return @reference_counter_api.get_number_of_references_from_revision_ids(rev_batch)
    end
    {}
  end

  def complete_score(score)
    completed_score = {}

    # If the score already has error key is because some API request failed some way
    completed_score['error'] = score.key?('error')

    # Fetch the value for 'deleted, or default to 'false if not present.
    completed_score['deleted'] = score.fetch('deleted', false)

    # features field has to contain the reference-counter scores if
    # different from nil. Otherwise, it should be the empty hash.
    completed_score['features'] =
      score.fetch('num_ref').nil? ? {} : { 'num_ref' => score['num_ref'] }

    completed_score
  end

  def ensure_complete_scores(scores)
    completed_scores = {}
    scores.each do |rev_id, score|
      completed_scores[rev_id] = complete_score(score)
    end
    completed_scores
  end
end
