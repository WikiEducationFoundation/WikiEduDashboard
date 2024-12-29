# frozen_string_literal: true

require 'rails_helper'

describe GetSystemMetrics, type: :service do
  let(:service) { described_class.new }

  describe '#initialize' do
    it 'initializes with valid Sidekiq queue data' do
      queues = YAML.load_file('config/sidekiq.yml')[:queues].reject { |q| q == 'very_long_update' }
      expect(service.instance_variable_get(:@queues)).to eq(queues)
    end
  end

  describe '#fetch_sidekiq_stats' do
    it 'returns Sidekiq stats with enqueued and active jobs' do
      stats = service.fetch_sidekiq_stats
      expect(stats).to be_a(Hash)
      expect(stats).to include(:enqueued_jobs, :active_jobs)
    end
  end

  describe '#fetch_queue_management_metrics' do
    it 'returns queue metrics with valid data' do
      metrics = service.fetch_queue_management_metrics
      expect(metrics).to be_a(Hash)
      expect(metrics).to include(:queues, :paused_queues, :all_operational)

      metrics[:queues].each do |queue|
        expect(queue).to include(:name, :size, :status, :latency)
        expect(queue[:latency]).to be_a(String)
      end
    end
  end

  describe '#get_queue_data' do
    it 'returns data for a single queue' do
      queue_name = service.instance_variable_get(:@queues).first
      queue = Sidekiq::Queue.new(queue_name)
      queue_data = service.get_queue_data(queue)

      expect(queue_data).to be_a(Hash)
      expect(queue_data).to include(:name, :size, :status, :latency)
    end
  end

  describe '#convert_latency' do
    it 'converts latency into human-readable format' do
      expect(service.convert_latency(30)).to eq('30 seconds')
      expect(service.convert_latency(90)).to eq('1 minute 30 seconds')
      expect(service.convert_latency(3600)).to eq('1 hour')
      expect(service.convert_latency(90000)).to eq('1 day 1 hour')
    end
  end

  describe '#format_time' do
    it 'formats time into main and sub-units' do
      formatted_time = service.format_time(3661, 3600, 'hour', 'minute')
      expect(formatted_time).to eq('1 hour 1 minute')
    end
  end
end
