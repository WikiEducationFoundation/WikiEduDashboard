# frozen_string_literal: true

module ClaimVerification
  # The hand-curated set of flagged revisions students may pick from, as
  # declared in config/claim_verification_rollout.yml.
  #
  # TEMPORARY. This is the initial rollout's allow-list, not the intended
  # serving strategy. While the config names any revisions, the exercise offers
  # only those, to every course; empty the list or delete the file and the full
  # harvested pool comes back. Nothing else in the app knows the list exists —
  # RelevantClaimRevisionsForCourse is the single point that consults it.
  #
  # The unit is the (article_id, mw_rev_id) pair rather than the revision id
  # alone: revision ids are unique within a wiki but not across them, and the
  # pool spans wikis.
  class RolloutList
    CONFIG_PATH = "#{Rails.root}/config/claim_verification_rollout.yml"

    class << self
      def active?
        pairs.any?
      end

      # The given VerificationClaim scope, narrowed to the rollout revisions —
      # or returned untouched when no list is configured.
      def filter(scope)
        approved = pairs
        return scope if approved.empty?
        scope.where(tuple_condition(approved))
      end

      # [[article_id, mw_rev_id], ...]
      def pairs
        # Reloaded every time outside production so curation changes land
        # without a restart, matching ClaimVerification::ExerciseForm.
        return load_pairs unless Rails.env.production?
        @pairs ||= load_pairs
      end

      private

      def load_pairs
        return [] unless File.exist?(CONFIG_PATH)
        revisions = YAML.load_file(CONFIG_PATH)['revisions'] || []
        revisions.filter_map do |revision|
          article_id = revision['article_id']
          mw_rev_id = revision['mw_rev_id']
          [article_id, mw_rev_id] if article_id.present? && mw_rev_id.present?
        end
      end

      def tuple_condition(approved)
        placeholders = Array.new(approved.length, '(?, ?)').join(', ')
        VerificationClaim.sanitize_sql_array(
          ['(verification_claims.article_id, verification_claims.mw_rev_id) ' \
           "IN (#{placeholders})", *approved.flatten]
        )
      end
    end
  end
end
