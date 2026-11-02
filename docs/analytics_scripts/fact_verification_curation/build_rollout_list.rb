# Builds the initial Fact Verification rollout list.
#
# This is the shortlist's output stage. build_article_inventory.rb scored all
# 468 harvested articles and produced the curation worksheet; the 54 that
# cleared the access gate were then hand-reviewed one by one, and that review
# is recorded in data/fv_rollout_shortlist.csv as a `verdict` per article. This
# script takes the two verdicts we are willing to put in front of students —
# strong_candidate and usable — and turns them into the actual rollout list.
#
# One row per article, keyed by (article_id, mw_rev_id) — the pair the serving
# layer (RelevantClaimRevisionsForCourse) groups claims by, so it is both the
# tile a student picks and what the eligibility filter matches on.
#
# Four articles were flagged twice. The hand review covered both diffs in every
# case, so both revisions are *eligible*, but the rollout ships one revision per
# article by decision: the one with the most claims, higher revision id breaking
# a tie. The revisions this drops are recorded in `other_flagged_revisions` and
# reported at the end of a run — restoring them is a matter of taking every
# revision here rather than the first.
#
# Claim counts come from the database rather than the worksheet, so the list
# cannot drift from the pool it describes; a mismatch is reported rather than
# silently accepted.
#
# Ordering is verdict tier first, then the share of an article's claims whose
# cited source is immediately readable. Absolute claim volume is deliberately
# NOT part of the ranking: a big pool does not make an article a better
# exercise, and ranking by it buried good small articles.
#
# Run with:
#   bundle exec rails runner docs/analytics_scripts/fact_verification_curation/build_rollout_list.rb
#
# Outputs, in data/ next to this script (ignored by .gitignore):
#   fv_rollout_list.csv - the rollout list, ranked, one row per article
#   fv_rollout_list.yml - the same set as (article_id, mw_rev_id) pairs
#
# This script used to write config/claim_verification_rollout.yml as well. That
# file has been curated by hand since the Fall 2026 claim review (articles
# removed, individual claims excluded by id), so the script no longer touches
# it: re-running would have thrown that curation away.

require 'csv'
require 'json'
require 'yaml'

DIR = File.dirname(__FILE__)
DATA_DIR = File.join(DIR, 'data')
ROLLOUT_VERDICTS = %w[strong_candidate usable].freeze

# Claim-level spot checks live in data/claim_checks/result_<slug>_<batch>.json, one
# object per claim with a `verdict`. The slug is the batch name the checking
# agents were given, not anything derivable from the data, so it is mapped by
# hand. Only a couple of articles have been checked this way — the column
# records provenance, it is not a gate.
CLAIM_CHECK_ARTICLES = {
  'honolulu' => 'Honolulu Courthouse riot',
  'poverty' => 'Diseases of poverty'
}.freeze

SUPPORTING_VERDICTS = %w[supported partially_supported].freeze

# --- claim-level spot checks --------------------------------------------------

# article title => {checked:, supported:, verdicts: {verdict => count}}
def claim_checks
  Dir[File.join(DATA_DIR, 'claim_checks', 'result_*.json')].each_with_object({}) do |path, acc|
    slug = File.basename(path).delete_prefix('result_').sub(/_\d+\.json\z/, '')
    title = CLAIM_CHECK_ARTICLES[slug]
    next warn("skipping unmapped claim-check file: #{File.basename(path)}") unless title

    entry = acc[title] ||= { checked: 0, supported: 0, verdicts: Hash.new(0) }
    JSON.parse(File.read(path)).each do |claim|
      entry[:checked] += 1
      entry[:supported] += 1 if SUPPORTING_VERDICTS.include?(claim['verdict'])
      entry[:verdicts][claim['verdict']] += 1
    end
  end
end

# --- pool state ---------------------------------------------------------------

# article_id => [[mw_rev_id, claim_count], ...] most claims first, newest wins a tie
def revisions_by_article(article_ids)
  VerificationClaim.where(article_id: article_ids)
                   .where.not(alert_id: nil).where.not(mw_rev_id: nil)
                   .group(:article_id, :mw_rev_id).count
                   .group_by { |(article_id, _rev), _n| article_id }
                   .transform_values do |rows|
                     rows.map { |(_a, rev), n| [rev, n] }.sort_by { |rev, n| [-n, -rev] }
                   end
end

def pct(numerator, denominator)
  return nil if denominator.to_i.zero?
  (100.0 * numerator.to_i / denominator.to_i).round(1)
end

# --- build --------------------------------------------------------------------

shortlist = CSV.read(File.join(DATA_DIR, 'fv_rollout_shortlist.csv'), headers: true)
selected = shortlist.select { |row| ROLLOUT_VERDICTS.include?(row['verdict']) }

checks = claim_checks
pool = revisions_by_article(selected.map { |row| row['article_id'].to_i })
warnings = []

articles = selected.map do |row|
  article_id = row['article_id'].to_i
  revisions = pool[article_id] || []
  title = row['article_title']
  pool_total = revisions.sum { |_rev, n| n }

  warnings << "#{title}: no claims in pool for article_id #{article_id}" if revisions.empty?
  if revisions.any? && pool_total != row['claim_count'].to_i
    warnings << "#{title}: worksheet says #{row['claim_count']} claims, " \
                "pool has #{pool_total} across #{revisions.length} revision(s)"
  end

  { row:, article_id:, revisions:, claim_count: pool_total,
    check: checks[title] }
end

# strong_candidate before usable, then most-readable sources first
articles.sort_by! do |entry|
  [ROLLOUT_VERDICTS.index(entry[:row]['verdict']),
   -entry[:row]['pct_claims_free_source'].to_f,
   entry[:row]['article_title']]
end

# One row per article: the most-claims revision ships, the rest are recorded.
rows = articles.map.with_index do |entry, index|
  chosen, *dropped = entry[:revisions]
  mw_rev_id, revision_claim_count = chosen
  entry.merge(rank: index + 1, mw_rev_id:, revision_claim_count:, dropped:)
end

dropped_claims = rows.sum { |entry| entry[:dropped].sum { |_rev, n| n } }

HEADERS = ['rank', 'tier', 'article_title', 'article_id', 'mw_rev_id',
           'rollout_claim_count', 'article_claim_count', 'other_flagged_revisions',
           'topic_area', 'claims_free_source', 'pct_claims_free_source',
           'usable_claim_estimate', 'citation_quality', 'claims_spot_checked',
           'spot_checked_supported', 'spot_check_verdicts', 'reviewed_in_pass',
           'article_url', 'diff_urls', 'rationale', 'red_flags',
           'good_example_claim'].freeze

csv_path = File.join(DATA_DIR, 'fv_rollout_list.csv')
CSV.open(csv_path, 'wb') do |csv|
  csv << HEADERS
  rows.each do |entry|
    row = entry[:row]
    check = entry[:check]
    csv << [entry[:rank], row['verdict'], row['article_title'], entry[:article_id],
            entry[:mw_rev_id], entry[:revision_claim_count], entry[:claim_count],
            entry[:dropped].map { |rev, n| "#{rev} (#{n})" }.join(' '),
            row['topic_area'],
            row['claims_free_source'], row['pct_claims_free_source'],
            row['usable_claim_estimate'], row['citation_quality'],
            check&.fetch(:checked), check&.fetch(:supported),
            check && check[:verdicts].map { |v, n| "#{v}:#{n}" }.join(' '),
            row['reviewed_in_pass'], row['article_url'], row['diff_urls'],
            row['rationale'], row['red_flags'], row['good_example_claim']]
  end
end

def rollout_entries(rows)
  rows.map do |entry|
    { 'article_id' => entry[:article_id], 'mw_rev_id' => entry[:mw_rev_id],
      'title' => entry[:row]['article_title'], 'tier' => entry[:row]['verdict'],
      'topic_area' => entry[:row]['topic_area'],
      'claim_count' => entry[:revision_claim_count] }
  end
end

yaml_path = File.join(DATA_DIR, 'fv_rollout_list.yml')
File.write(yaml_path, {
  'generated_by' => 'docs/analytics_scripts/fact_verification_curation/build_rollout_list.rb',
  'source' => 'fv_rollout_shortlist.csv verdicts strong_candidate + usable',
  'revisions' => rollout_entries(rows)
}.to_yaml)


# --- report -------------------------------------------------------------------

by_tier = articles.group_by { |entry| entry[:row]['verdict'] }
by_area = articles.group_by { |entry| entry[:row]['topic_area'].to_s.split(' (').first }

puts "#{rows.length} articles, one revision each, " \
     "#{rows.sum { |entry| entry[:revision_claim_count] }} claims"
ROLLOUT_VERDICTS.each { |tier| puts "  #{tier}: #{(by_tier[tier] || []).length}" }
puts "topic areas: #{by_area.map { |area, list| "#{area} #{list.length}" }.sort.join(', ')}"
if dropped_claims.positive?
  extra = rows.select { |entry| entry[:dropped].any? }
  puts "#{dropped_claims} claims left out on #{extra.length} second flagged revisions:"
  extra.each do |entry|
    puts "  #{entry[:row]['article_title']}: keeping #{entry[:mw_rev_id]} " \
         "(#{entry[:revision_claim_count]}), dropping " \
         "#{entry[:dropped].map { |rev, n| "#{rev} (#{n})" }.join(', ')}"
  end
end
puts "wrote #{csv_path}"
puts "wrote #{yaml_path}"

return if warnings.empty?

puts "\n#{warnings.length} data warnings:"
warnings.each { |warning| puts "  #{warning}" }
