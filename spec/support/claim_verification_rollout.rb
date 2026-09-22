# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/rollout_list"

# The curated rollout allow-list (config/claim_verification_rollout.yml) names
# real article, revision and claim ids from the production claim pool. Left
# switched on, it would filter away every claim a spec builds for itself (and
# could exclude one by a colliding id), so specs run with the gate off and opt
# in with `rollout_revisions` when they mean to exercise it.
module ClaimVerificationRolloutHelper
  # Restrict the exercise to the given [article_id, mw_rev_id] pairs, and
  # curate out the given claim ids.
  def rollout_revisions(*pairs, excluding: [])
    allow(ClaimVerification::RolloutList).to receive(:pairs).and_return(pairs)
    allow(ClaimVerification::RolloutList).to receive(:excluded_claim_ids)
      .and_return(excluding.to_set)
  end

  # Read config/claim_verification_rollout.yml for real.
  def real_rollout_list
    allow(ClaimVerification::RolloutList).to receive(:pairs).and_call_original
    allow(ClaimVerification::RolloutList).to receive(:excluded_claim_ids).and_call_original
  end
end

RSpec.configure do |config|
  config.include ClaimVerificationRolloutHelper
  config.before { rollout_revisions }
end
