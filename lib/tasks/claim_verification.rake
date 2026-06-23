# frozen_string_literal: true

namespace :claim_verification do
  desc 'Harvest claims added in mainspace AiEditAlert revisions into the pool'
  task harvest_pool: :environment do
    # Mainspace AiEditAlerts with a flagged revision. namespace is pre-filtered in
    # SQL; #mainspace? (title-based) is the authoritative check, confirmed per alert.
    alerts = AiEditAlert.joins(:article)
                        .where(articles: { namespace: Article::Namespaces::MAINSPACE })
                        .where.not(revision_id: nil)
    alerts = alerts.limit(ENV['LIMIT'].to_i) if ENV['LIMIT'].present?

    harvested = 0
    # Serial on purpose — one parser API call per alert; do not parallelize.
    alerts.find_each do |alert|
      next unless alert.mainspace?
      # Skip revisions already represented in the pool to avoid redundant API calls.
      next if VerificationClaim.exists?(wiki_id: alert.article.wiki_id,
                                        mw_rev_id: alert.revision_id)
      claims = HarvestAiEditAlertClaims.new(alert).claims
      harvested += claims.size
      puts "Alert ##{alert.id} #{alert.article.title} (rev #{alert.revision_id}): " \
           "#{claims.size} claims"
    end
    puts "Harvested #{harvested} claims into the verification-claim pool."
  end
end
