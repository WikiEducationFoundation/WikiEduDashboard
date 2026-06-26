# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/harvest_ai_edit_alert_claims"

# Harvests claims from mainspace AiEditAlert revisions into the verification-claim
# pool. Revisions already represented in the pool are excluded set-based, in one
# correlated NOT EXISTS query against the (wiki_id, mw_rev_id) index — no
# per-alert existence check. The title-based #mainspace? check is the
# authoritative namespace filter and still runs per alert (it's a cheap in-memory
# check; it makes no API call). Progress is reported through optional callables
# (total/at/store) so a Sidekiq worker can surface live progress; called with no
# callables it runs silently for rake/console use. One parser API call per
# harvested alert — kept serial on purpose. Records a summary in the
# `claim_harvest` Setting.
#
# Note: a mainspace alert that yields zero claims leaves no pool entry, so it is
# re-fetched on the next incremental run. `full_rescan: true` deliberately
# re-scans everything (it skips the dedup clause).
class HarvestClaimPool
  SETTING_KEY = 'claim_harvest'

  # Correlated anti-join: a revision is "done" once any claim from it is pooled.
  NOT_HARVESTED_SQL = <<~SQL.squish.freeze
    NOT EXISTS (
      SELECT 1 FROM verification_claims vc
      WHERE vc.wiki_id = articles.wiki_id AND vc.mw_rev_id = alerts.revision_id
    )
  SQL

  attr_reader :harvested, :processed, :skipped, :errors

  def initialize(full_rescan: false, total: nil, at: nil, store: nil)
    @full_rescan = full_rescan
    @total = total
    @at = at
    @store = store
    @harvested = 0
    @processed = 0
    @skipped = 0
    @errors = 0
    perform
  end

  private

  def perform
    scope = alerts_to_harvest
    @total&.call(scope.count)
    scope.find_each.with_index(1) { |alert, index| harvest_alert(alert, index) }
    record_run
  end

  # One failing alert must not abort the whole batch: log it and move on. The
  # API layer already retries transient errors (429s etc.) with backoff, so an
  # exception reaching here is unexpected — captured to Sentry for follow-up.
  def harvest_alert(alert, index)
    unless alert.mainspace?
      @skipped += 1
      return report(index, "skipped non-mainspace alert ##{alert.id}")
    end
    count = HarvestAiEditAlertClaims.new(alert).claims.size
    @harvested += count
    @processed += 1
    report(index, "alert ##{alert.id} #{alert.article.title}: #{count} claims")
  rescue StandardError => e
    @errors += 1
    Sentry.capture_exception(e)
    report(index, "error on alert ##{alert.id}: #{e.class}")
  end

  def report(index, message)
    @at&.call(index, message)
    @store&.call(harvested: @harvested, processed: @processed,
                 skipped: @skipped, errors: @errors)
  end

  def alerts_to_harvest
    scope = AiEditAlert.joins(:article)
                       .where(articles: { namespace: Article::Namespaces::MAINSPACE })
                       .where.not(revision_id: nil)
    scope = scope.where(NOT_HARVESTED_SQL) unless @full_rescan
    scope
  end

  def record_run
    Setting.set_hash(SETTING_KEY, 'last_run_at', Time.zone.now)
    Setting.set_hash(SETTING_KEY, 'last_summary',
                     { 'processed' => @processed, 'harvested' => @harvested,
                       'skipped' => @skipped, 'errors' => @errors,
                       'full_rescan' => @full_rescan })
  end
end
