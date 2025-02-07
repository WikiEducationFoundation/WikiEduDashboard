# frozen_string_literal: true

require 'rails_helper'

describe SystemMetrics do
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

    it 'identifies paused queues correctly' do
      allow_any_instance_of(Sidekiq::Queue).to receive(:paused?).and_return(true)
      metrics = service.fetch_queue_management_metrics
      expect(metrics[:paused_queues]).not_to be_empty
      expect(metrics[:all_operational]).to eq(false)
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

  describe '#get_queue_status' do
    it 'returns Normal for queues under threshold latency' do
      expect(service.get_queue_status('short_update', 1.hour)).to eq('Normal')
      expect(service.get_queue_status('medium_update', 6.hours)).to eq('Normal')
      expect(service.get_queue_status('long_update', 12.hours)).to eq('Normal')
      expect(service.get_queue_status('daily_update', 12.hours)).to eq('Normal')
      expect(service.get_queue_status('constant_update', 12.minutes)).to eq('Normal')
      expect(service.get_queue_status('default', 0)).to eq('Normal')
    end

    it 'returns Backlogged for queues exceeding threshold latency' do
      expect(service.get_queue_status('short_update', 3.hours)).to eq('Backlogged')
      expect(service.get_queue_status('medium_update', 13.hours)).to eq('Backlogged')
      expect(service.get_queue_status('long_update', 26.hours)).to eq('Backlogged')
      expect(service.get_queue_status('daily_update', 26.hours)).to eq('Backlogged')
      expect(service.get_queue_status('constant_update', 16.minutes)).to eq('Backlogged')
      expect(service.get_queue_status('default', 2)).to eq('Backlogged')
    end
  end

  describe '#convert_latency' do
    it 'converts latency in seconds to more readable formats' do
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
