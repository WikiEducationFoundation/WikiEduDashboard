# frozen_string_literal: true

namespace :claim_verification do
  desc 'Harvest claims added in mainspace AiEditAlert revisions into the pool. ' \
       'Runs inline; the admin page enqueues HarvestClaimPoolWorker instead. ' \
       'ENV: LIMIT=n caps alerts scanned, RESCAN=1 ignores the pool-dedup filter.'
  task harvest_pool: :environment do
    limit = ENV['LIMIT'].presence&.to_i
    full_rescan = ENV['RESCAN'].present?
    # Print per-alert progress to stdout when run from the CLI.
    at = ->(index, message) { puts "[#{index}] #{message}" }
    harvest = HarvestClaimPool.new(full_rescan:, limit:, at:)
    puts "Harvested #{harvest.harvested} claims from #{harvest.processed} alerts " \
         "(#{harvest.skipped} skipped) into the verification-claim pool."
  end
end
