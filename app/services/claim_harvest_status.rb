# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/harvest_claim_pool"

# Assembles the claim-pool harvest status for the admin page: the live progress
# of the current/last harvest job (from Sidekiq::Status, via the job id stashed
# in the `claim_harvest` Setting) plus the persisted last-run summary and the
# current pool size. Returns a plain hash via #as_json for the status endpoint.
class ClaimHarvestStatus
  ACTIVE_STATES = %i[queued retrying working].freeze

  def initialize
    @setting = Setting.find_by(key: HarvestClaimPool::SETTING_KEY)&.value || {}
    @job_id = @setting['job_id']
    @status = job_status
  end

  def as_json(*)
    {
      pool_size: VerificationClaim.count,
      last_run_at: @setting['last_run_at'],
      last_summary: @setting['last_summary'],
      job: job_progress
    }
  end

  private

  def job_status
    return nil if @job_id.blank?
    Sidekiq::Status.status(@job_id)
  end

  def job_progress
    return nil if @status.nil?
    {
      status: @status,
      active: ACTIVE_STATES.include?(@status),
      pct_complete: Sidekiq::Status.pct_complete(@job_id),
      at: Sidekiq::Status.at(@job_id),
      total: Sidekiq::Status.total(@job_id),
      message: Sidekiq::Status.message(@job_id),
      harvested: get(:harvested),
      processed: get(:processed),
      skipped: get(:skipped),
      errors: get(:errors),
      full_rescan: Sidekiq::Status.get(@job_id, :full_rescan) == 'true'
    }
  end

  def get(field)
    Sidekiq::Status.get(@job_id, field)&.to_i
  end
end
