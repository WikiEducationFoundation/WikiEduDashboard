# frozen_string_literal: true

module ClaimVerification
  # The hand-curated set of flagged revisions students may pick from, and the
  # individual claims curated out of them, as declared in
  # config/claim_verification_rollout.yml.
  #
  # TEMPORARY. This is the initial rollout's allow-list, not the intended
  # serving strategy. While the config names any revisions, the exercise offers
  # only those, to every course; empty the list or delete the file and the full
  # harvested pool comes back. The per-claim exclusions are subtractive and
  # independent of that gate, so they keep applying to the full pool once the
  # revision list is retired. Nothing else in the app knows the list exists —
  # RelevantClaimRevisionsForCourse (tiles and counts) and AnnotateRevisionClaims
  # (which claims get highlighted) are the two points that consult it.
  #
  # The revision unit is the (article_id, mw_rev_id) pair rather than the
  # revision id alone: revision ids are unique within a wiki but not across
  # them, and the pool spans wikis.
  class RolloutList
    CONFIG_PATH = "#{Rails.root}/config/claim_verification_rollout.yml"

    class << self
      def active?
        pairs.any?
      end

      # The given VerificationClaim scope, narrowed to the rollout revisions and
      # stripped of the excluded claims — or returned untouched when neither is
      # configured.
      def filter(scope)
        approved = pairs
        scope = scope.where(tuple_condition(approved)) if approved.any?
        without_excluded(scope)
      end

      # The given scope minus the excluded claims — and minus every other pool
      # row for the same sentence in the same revision. A sentence with several
      # citations is pooled once per citation but shown once, so what the
      # curators reviewed and excluded is the sentence: its other rows have to
      # go too, or they would surface in the viewer and in the tile counts.
      def without_excluded(scope)
        excluded = excluded_claim_ids
        return scope if excluded.empty?
        scope.where.not(excluded_sentence_exists(excluded))
      end

      # [[article_id, mw_rev_id], ...]
      def pairs
        config[:pairs]
      end

      # The VerificationClaim ids curated out of the exercise, as a Set.
      def excluded_claim_ids
        config[:excluded_claim_ids]
      end

      private

      def config
        # Reloaded every time outside production so curation changes land
        # without a restart, matching ClaimVerification::ExerciseForm.
        return load_config unless Rails.env.production?
        @config ||= load_config
      end

      def load_config
        return { pairs: [], excluded_claim_ids: Set.new } unless File.exist?(CONFIG_PATH)
        yaml = YAML.load_file(CONFIG_PATH)
        { pairs: load_pairs(yaml['revisions'] || []),
          excluded_claim_ids: (yaml['excluded_claim_ids'] || []).map(&:to_i).to_set }
      end

      def load_pairs(revisions)
        revisions.filter_map do |revision|
          article_id = revision['article_id']
          mw_rev_id = revision['mw_rev_id']
          [article_id, mw_rev_id] if article_id.present? && mw_rev_id.present?
        end
      end

      # EXISTS (an excluded claim with this row's article, revision and sentence).
      def excluded_sentence_exists(excluded)
        VerificationClaim.from('verification_claims ex')
                         .where(ex: { id: excluded.to_a })
                         .where('ex.article_id = verification_claims.article_id')
                         .where('ex.mw_rev_id = verification_claims.mw_rev_id')
                         .where('ex.sentence = verification_claims.sentence')
                         .arel.exists
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
