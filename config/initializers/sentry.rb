Sentry.init do |config|
  config.dsn = ENV['sentry_dsn']
  config.enabled_environments = %w[development staging production test]
  host_rate = ENV['sentry_sample_rate'].to_f
  config.traces_sample_rate = host_rate

  # Course update jobs are queued from a sampled scheduler trace (#7124). Every
  # transaction in a trace shares one sample_rand, so a numeric rate would keep or
  # drop all of a trace's update jobs together. A boolean is an independent draw per job,
  # gated on host_rate so a host with sentry_sample_rate=0 still records no spans at all.
  update_jobs = %w[Sidekiq/CourseDataUpdateWorker Sidekiq/ConstantUpdateWorker]
  update_job_rate = 0.001
  config.traces_sampler = lambda do |context|
    if update_jobs.include?(context.dig(:transaction_context, :name))
      next host_rate.positive? && rand < update_job_rate
    end
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
