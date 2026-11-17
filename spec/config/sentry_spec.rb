# frozen_string_literal: true

require 'rails_helper'

# config/initializers/sentry.rb independently samples ~0.1% of course update
# jobs instead of inheriting the scheduler's sampling decision, and drops Rails
# cache spans before sending a transaction (#7124, #7154).
describe 'Sentry initializer' do
  initializer_path = Rails.root.join('config/initializers/sentry.rb')

  let(:sampler) { Sentry.configuration.traces_sampler }
  let(:host_rate) { Sentry.configuration.traces_sample_rate }

  # host_rate is read from ENV and closed over when the initializer runs at boot, so
  # exercising another value means reloading it under a modified ENV, then reloading
  # it again unmodified so later examples see the real test-env configuration.
  def with_host_rate(rate, path)
    ClimateControl.modify('sentry_sample_rate' => rate.to_s) { load path }
    yield
  ensure
    load path
  end

  def sampling_context(name, parent_sampled: nil)
    { transaction_context: { name:, op: 'queue.process' }, parent_sampled: }
  end

  describe 'traces_sampler' do
    # A numeric rate would be sampled against sample_rand, which is the same for
    # every transaction in a trace, so update jobs get a boolean per-job draw.
    it 'draws independently per course update job' do
      with_host_rate(0.01, initializer_path) do
        context = sampling_context('Sidekiq/CourseDataUpdateWorker', parent_sampled: true)
        results = Array.new(20_000) { sampler.call(context) }
        expect(results.count(true)).to be_between(5, 50)
      end
    end

    it 'draws independently per constant update job' do
      with_host_rate(0.01, initializer_path) do
        context = sampling_context('Sidekiq/ConstantUpdateWorker', parent_sampled: true)
        results = Array.new(20_000) { sampler.call(context) }
        expect(results.count(true)).to be_between(5, 50)
      end
    end

    # A host running with sentry_sample_rate=0 (e.g. dashboard.wikiedu.org, staging)
    # must record zero spans, including from update jobs.
    it 'never samples an update job when the host rate is 0' do
      with_host_rate(0, initializer_path) do
        context = sampling_context('Sidekiq/CourseDataUpdateWorker', parent_sampled: true)
        results = Array.new(1000) { sampler.call(context) }
        expect(results.count(true)).to eq(0)
      end
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

  # Regression for #7154: these go through continue_trace/start_transaction, as a
  # Sidekiq job does, because the shared-trace bug only showed up on that path.
  describe 'sampling across a shared trace' do
    def headers_for_trace(trace_id, sample_rand)
      {
        'sentry-trace' => "#{trace_id}-#{SecureRandom.hex(8)}-1",
        'baggage' => "sentry-trace_id=#{trace_id},sentry-sample_rand=#{sample_rand}," \
                     'sentry-sample_rate=0.01,sentry-sampled=true'
      }
    end

    # with_host_rate reloads the initializer, which replaces Sentry.configuration,
    # so this stub is applied fresh here rather than in a before hook.
    def sampled_count(trace_id, sample_rand, count: 20_000)
      allow(Sentry.configuration).to receive(:tracing_enabled?).and_return(true)
      headers = headers_for_trace(trace_id, sample_rand)
      Array.new(count) do
        transaction = Sentry.continue_trace(headers, name: 'Sidekiq/CourseDataUpdateWorker',
                                                     op: 'queue.process', source: :task)
        Sentry.start_transaction(transaction:, name: 'Sidekiq/CourseDataUpdateWorker',
                                 op: 'queue.process').sampled
      end.count(true)
    end

    # 20,000 jobs at 0.1% gives about 20 kept; 5-50 separates that from
    # "none" or "all" with negligible chance of a false failure.
    it 'samples about 0.1% of a trace whose sample_rand is above the rate' do
      with_host_rate(0.01, initializer_path) do
        expect(sampled_count(SecureRandom.hex(16), '0.003350')).to be_between(5, 50)
      end
    end

    it 'samples about 0.1% of a trace whose sample_rand is below the rate' do
      with_host_rate(0.01, initializer_path) do
        expect(sampled_count(SecureRandom.hex(16), '0.000500')).to be_between(5, 50)
      end
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
