# frozen_string_literal: true

require 'rails_helper'

# config/initializers/sentry.rb samples course update jobs at a fixed low rate
# instead of inheriting the scheduler's sampling decision, and drops Rails
# cache spans before sending a transaction (#7124).
describe 'Sentry initializer' do
  let(:sampler) { Sentry.configuration.traces_sampler }
  let(:host_rate) { Sentry.configuration.traces_sample_rate }

  def sampling_context(name, parent_sampled: nil)
    { transaction_context: { name:, op: 'queue.process' }, parent_sampled: }
  end

  describe 'traces_sampler' do
    it 'samples a course update job at 0.1%, ignoring a sampled parent' do
      context = sampling_context('Sidekiq/CourseDataUpdateWorker', parent_sampled: true)
      expect(sampler.call(context)).to eq(0.001)
    end

    it 'samples a constant update job at 0.1%, ignoring a sampled parent' do
      context = sampling_context('Sidekiq/ConstantUpdateWorker', parent_sampled: true)
      expect(sampler.call(context)).to eq(0.001)
    end

    it 'keeps the parent decision for other transactions' do
      context = sampling_context('Sidekiq/UpdateCourseWorker', parent_sampled: true)
      expect(sampler.call(context)).to be(true)
    end

    it 'uses the host rate for other transactions without a parent' do
      context = sampling_context('Sidekiq/UpdateCourseWorker')
      expect(sampler.call(context)).to eq(host_rate)
    end
  end

  describe 'before_send_transaction' do
    it 'drops cache spans and keeps the rest' do
      spans = [{ op: 'cache.get' }, { op: 'db.sql.active_record' }, { op: 'cache.put' }]
      event = instance_double(Sentry::TransactionEvent, spans:)

      Sentry.configuration.before_send_transaction.call(event, {})

      expect(spans).to eq([{ op: 'db.sql.active_record' }])
    end
  end
end
