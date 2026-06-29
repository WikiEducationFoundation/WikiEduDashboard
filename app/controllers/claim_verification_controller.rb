# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/claim_harvest_status"
require_dependency "#{Rails.root}/app/workers/harvest_claim_pool_worker"

# Admin page for the claim-verification pool: kick off a harvest and watch its
# progress. The harvest itself runs in HarvestClaimPoolWorker; this controller
# enqueues it and serves the status the page polls.
class ClaimVerificationController < ApplicationController
  layout 'admin'
  before_action :require_admin_permissions

  def index; end

  def status
    render json: ClaimHarvestStatus.new
  end

  def harvest
    job_id = HarvestClaimPoolWorker.harvest(full_rescan: params[:full_rescan].present?)
    render json: { job_id:, status: ClaimHarvestStatus.new }
  end
end
