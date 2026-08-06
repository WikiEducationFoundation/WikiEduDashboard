# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/rollout_list"

# The curated rollout allow-list (config/claim_verification_rollout.yml) names
# real article and revision ids from the production claim pool. Left switched
# on, it would filter away every claim a spec builds for itself, so specs run
# with the gate off and opt in with `rollout_revisions` when they mean to
# exercise it.
module ClaimVerificationRolloutHelper
  # Restrict the exercise to the given [article_id, mw_rev_id] pairs.
  def rollout_revisions(*pairs)
    allow(ClaimVerification::RolloutList).to receive(:pairs).and_return(pairs)
  end

  # Read config/claim_verification_rollout.yml for real.
  def real_rollout_list
    allow(ClaimVerification::RolloutList).to receive(:pairs).and_call_original
  end
end

RSpec.configure do |config|
  config.include ClaimVerificationRolloutHelper
  config.before { rollout_revisions }
end
