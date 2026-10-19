Sentry.init do |config|
  config.dsn = ENV['sentry_dsn']
  config.enabled_environments = %w[development staging production test]
  host_rate = ENV['sentry_sample_rate'].to_f
  config.traces_sample_rate = host_rate

  # Course update jobs are queued from a sampled scheduler trace, and without a
  # sampler they'd inherit that decision whatever this host's rate is (#7124).
  # A fixed, low rate keeps their span volume small while still giving Sentry
  # enough traces to detect N+1 queries.
  update_jobs = %w[Sidekiq/CourseDataUpdateWorker Sidekiq/ConstantUpdateWorker]
  update_job_rate = 0.001
  config.traces_sampler = lambda do |context|
    next update_job_rate if update_jobs.include?(context.dig(:transaction_context, :name))
    next context[:parent_sampled] unless context[:parent_sampled].nil?
    host_rate
  end

  # Rails cache reads and writes make up most spans on some pages
  # (e.g. CampaignsController#articles) and add little to a trace.
  config.before_send_transaction = lambda do |event, _hint|
    event.spans&.reject! { |span| span[:op].to_s.start_with?('cache.') }
    event
  end
end
