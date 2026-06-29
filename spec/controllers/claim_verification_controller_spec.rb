# frozen_string_literal: true

require 'rails_helper'

describe ClaimVerificationController, type: :controller do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  def sign_in_as(signed_in_user)
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user).and_return(signed_in_user)
  end

  describe 'GET #status' do
    it 'returns pool status JSON for an admin' do
      sign_in_as(admin)
      get :status, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to have_key('pool_size')
    end

    it 'rejects non-admins' do
      sign_in_as(user)
      get :status, format: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST #harvest' do
    before { sign_in_as(admin) }

    it 'enqueues a harvest and returns the job id' do
      allow(HarvestClaimPoolWorker).to receive(:harvest).and_return('job-123')
      post :harvest, format: :json
      expect(HarvestClaimPoolWorker).to have_received(:harvest).with(full_rescan: false)
      expect(JSON.parse(response.body)['job_id']).to eq('job-123')
    end

    it 'requests a full re-scan when asked' do
      allow(HarvestClaimPoolWorker).to receive(:harvest).and_return('job-123')
      post :harvest, params: { full_rescan: 'true' }, format: :json
      expect(HarvestClaimPoolWorker).to have_received(:harvest).with(full_rescan: true)
    end
  end
end
