# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/lift_wing_api"
require_dependency "#{Rails.root}/lib/reference_counter_api"

#= Handles the logic to decide how to retrieve revision data for a given wiki.
# This involves to determine if the given wiki is supported for both Lift Wing API and
# reference-counter API (e.g en.wikipedia), only for Lift Wing API (wikidata),
# or only for reference-counter API (e.g es.wikipedia).
class RevisionScoreApiHandler
  def initialize(language: 'en', project: 'wikipedia', wiki: nil, update_service: nil)
    @update_service = update_service
    @wiki = wiki || Wiki.get_or_create(language:, project:)
    # Initialize LiftWingApi if the wiki is valid for it
    @lift_wing_api = LiftWingApi.new(@wiki, @update_service) if LiftWingApi.valid_wiki?(@wiki)
    # Initialize ReferenceCounterApi if the wiki is valid for it
    if ReferenceCounterApi.valid_wiki?(@wiki)
      @reference_counter_api = ReferenceCounterApi.new(@wiki, @update_service)
    end
  end

  # Returns data from LiftWing API and/or reference-counter API.
  # The response has the following format:
  # { "rev_0"=>
  #     { "wp10"=>0.296976285416441736e2,
  #       "features"=> { "num_ref"=>0 },
  #       "deleted"=>false,
  #       "prediction"=>"Start" },
  #   ...,
  #   "rev_n"=>
  #     { "wp10"=>0.2929458626376752846e2,
  #       "features"=> nil,
  #       "deleted"=>false,
  #       "prediction"=>"Start" }
  # }
  #
  # For wikidata, "features" key contains Liftwing features. For other wikis, "features"
  # key contains reference-counter response (or nil).
  def get_revision_data(rev_batch)
    scores = maybe_get_lift_wing_data rev_batch
    scores.deep_merge!(maybe_get_reference_data(rev_batch))
    ensure_complete_scores scores
  end

  ##################
  # Helper methods #
  ##################
  private

  def maybe_get_lift_wing_data(rev_batch)
    return @lift_wing_api.get_revision_data rev_batch if LiftWingApi.valid_wiki?(@wiki)
    {}
  end

  def maybe_get_reference_data(rev_batch)
    if ReferenceCounterApi.valid_wiki?(@wiki)
      return @reference_counter_api.get_number_of_references_from_revision_ids(rev_batch)
    end
    {}
  end

  def complete_score(score)
    completed_score = {}

    # Fetch the value for 'wp10' and 'prediction', or default to nil if not present.
    completed_score['wp10'] = score.fetch('wp10', nil)
    completed_score['prediction'] = score.fetch('prediction', nil)
    # Fetch the value for 'deleted, or default to 'false if not present.
    completed_score['deleted'] = score.fetch('deleted', false)

    # Ensure 'features' has the correct value (hash or nil).
    # For Wikidata, 'features' has to contain the LiftWing features.
    completed_score['features'] =
      if @wiki.project == 'wikidata'
        score.fetch('features', nil)
      else
        # For other wikis, 'features' has to contain the reference-counter scores if
        # different from nil. Otherwise, it should be nil.
        score.fetch('num_ref').nil? ? nil : { 'num_ref' => score['num_ref'] }
      end

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
