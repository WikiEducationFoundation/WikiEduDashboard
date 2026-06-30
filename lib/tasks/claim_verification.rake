# frozen_string_literal: true

namespace :claim_verification do
  desc 'Harvest claims added in mainspace AiEditAlert revisions into the pool. ' \
       'Runs inline; the admin page enqueues HarvestClaimPoolWorker instead. ' \
       'ENV: RESCAN=1 ignores the pool-dedup filter.'
  task harvest_pool: :environment do
    full_rescan = ENV['RESCAN'].present?
    # Print per-alert progress to stdout when run from the CLI.
    at = ->(index, message) { puts "[#{index}] #{message}" }
    harvest = HarvestClaimPool.new(full_rescan:, at:)
    puts "Harvested #{harvest.harvested} claims from #{harvest.processed} alerts " \
         "(#{harvest.skipped} skipped) into the verification-claim pool."
  end
end
