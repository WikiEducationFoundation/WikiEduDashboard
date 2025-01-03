# frozen_string_literal: true

require 'rails_helper'

describe SystemStatusController, type: :request do
  describe '#index' do
    it 'sets @sidekiq_stats' do
      get '/status'

      expect(assigns(:sidekiq_stats)).to be_a(Hash)
      expect(assigns(:sidekiq_stats)).to include(:enqueued_jobs, :active_jobs)
    end

    it 'sets @queue_metrics' do
      get '/status'

      queue_metrics = assigns(:queue_metrics)
      expect(queue_metrics).to be_a(Hash)
      expect(queue_metrics).to include(:queues, :paused_queues, :all_operational)

      expect(queue_metrics[:queues]).to all(include(:name, :size, :status, :latency))
    end

    it 'renders the index template' do
      get '/status'
      expect(response).to render_template(:index)
    end
  end
end
