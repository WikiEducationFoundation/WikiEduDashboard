# Builds a curation worksheet for the initial Fact Verification rollout.
#
# The verification-claim pool holds every cited claim harvested from mainspace
# AiEditAlert revisions. For the first rollout we want to hand-pick a subset of
# *articles* to point students at, favoring ones where (a) the cited sources
# are actually readable online without a library proxy, and (b) the AI-added
# content is plausible-looking rather than obvious slop — the exercise is about
# finding text that reads as well-sourced but isn't actually supported by the
# citation.
#
# This script emits two CSVs from local data only. It makes no network calls,
# so every access-related column is a *prior* based on the source's host, not a
# verified check. See source_access_domains.yml for that mapping and
# subject_disciplines.yml for the discipline buckets.
#
# Run with:
#   bundle exec rails runner docs/analytics_scripts/fact_verification_curation/build_article_inventory.rb
#
# Outputs, in data/ next to this script (ignored by .gitignore):
#   fv_article_inventory.csv - one row per article, the curation worksheet
#   fv_claim_detail.csv      - one row per claim, for reading the actual text

require 'csv'
require 'yaml'
require 'uri'
require 'fileutils'

DIR = File.dirname(__FILE__)
DATA_DIR = File.join(DIR, 'data')
FileUtils.mkdir_p(DATA_DIR)
SHORT_SENTENCE_CHARS = 80
STUFFING_THRESHOLD = 4

# --- classification tables ----------------------------------------------------

access_config = YAML.load_file(File.join(DIR, 'source_access_domains.yml'))
discipline_config = YAML.load_file(File.join(DIR, 'subject_disciplines.yml'))

# host (www-stripped) => tier
DOMAIN_TIERS = access_config['tiers'].each_with_object({}) do |(tier, spec), map|
  (spec['domains'] || []).each { |d| map[d.downcase.delete_prefix('www.')] = tier }
end
SUFFIX_RULES = access_config['suffix_rules'] || []
WEAK_SOURCE_DOMAINS = (access_config['weak_source_domains'] || [])
                      .map { |d| d.downcase.delete_prefix('www.') }.to_set

SUBJECT_DISCIPLINES = discipline_config.each_with_object({}) do |(bucket, subjects), map|
  subjects.each { |s| map[s.to_s.strip.downcase] = bucket }
end

# `unclassified` is the long tail: ordinary web hosts that are neither known
# publishers nor obviously institutional. Most are probably readable; the label
# means "not predicted", not "not available".
ACCESS_TIERS = %w[open paywalled abstract_only doi_redirect unclassified].freeze

def host_for(url)
  host = URI.parse(url.strip).host
  host&.downcase&.delete_prefix('www.')
rescue URI::InvalidURIError, ArgumentError
  # Fall back to a crude parse; a few harvested URLs have stray characters.
  url.to_s.downcase.sub(%r{\Ahttps?://}, '').split('/').first&.delete_prefix('www.')
end

# Exact host, then each parent domain, then the ordered suffix rules.
def access_tier_for(host)
  return 'unclassified' if host.blank?

  labels = host.split('.')
  (0..(labels.length - 2)).each do |i|
    tier = DOMAIN_TIERS[labels[i..].join('.')]
    return tier if tier
  end

  SUFFIX_RULES.each do |rule|
    return rule['tier'] if rule['suffix'] && host.end_with?(rule['suffix'])
    return rule['tier'] if rule['contains'] && host.include?(rule['contains'])
  end

  'unclassified'
end

def discipline_for(subject)
  key = subject.to_s.strip.downcase
  return 'unclassified' if key.empty?
  SUBJECT_DISCIPLINES[key] || 'unclassified'
end

def pct(numerator, denominator)
  return nil if denominator.nil? || denominator.zero?
  (100.0 * numerator / denominator).round(1)
end

# --- load ---------------------------------------------------------------------

puts 'Loading claim pool...'
claims = VerificationClaim.all.to_a
by_article = claims.group_by(&:article_id)
articles = Article.where(id: by_article.keys).index_by(&:id)
alerts = Alert.where(id: claims.map(&:alert_id).compact.uniq).index_by(&:id)
courses = Course.where(id: claims.map(&:source_course_id).compact.uniq).index_by(&:id)
puts "#{claims.size} claims across #{by_article.size} articles."

# Per-claim derived facts, reused by both CSVs.
claim_facts = claims.each_with_object({}) do |claim, memo|
  host = claim.source_url.present? ? host_for(claim.source_url) : nil
  memo[claim.id] = {
    host:,
    tier: claim.offline_source? ? 'offline' : (host ? access_tier_for(host) : 'unclassified')
  }
end

# --- article rows -------------------------------------------------------------

ARTICLE_HEADERS = [
  # identity
  'article_id', 'article_title', 'article_url', 'quality_rating', 'average_views',
  'article_deleted',
  # provenance
  'subject', 'discipline', 'courses', 'revision_count', 'latest_rev_timestamp',
  'diff_urls', 'pangram_urls',
  # AI-detection signals from the alert
  'max_fraction_ai_generated', 'max_ai_likelihood', 'predicted_llm',
  'chars_added_after_alert',
  # claim volume
  'claim_count', 'sentence_count', 'distinct_sources', 'refs_per_sentence',
  'max_refs_one_sentence',
  # source accessibility (heuristic, from host only)
  'claims_with_url', 'offline_sources', 'pct_offline',
  'access_open', 'access_paywalled', 'access_abstract_only',
  'access_doi_redirect', 'access_unclassified',
  'pct_open_of_all', 'pct_open_of_online',
  'claims_with_archive_url', 'distinct_domains', 'top_domains',
  # content-quality heuristics
  'weak_source_claims', 'mean_sentence_chars', 'short_sentences',
  'pct_short_sentences', 'pct_sentences_with_number', 'repeated_sentence_claims',
  'citation_stuffing',
  # left blank for the reviewer. `topic_override` matters more than it looks:
  # `discipline` is derived from the *course's* subject, not the article's, so a
  # Books course that edited an agriculture article shows up as humanities.
  'topic_override', 'access_spot_check', 'content_quality', 'include',
  'reviewer_notes'
].freeze

rows = by_article.map do |article_id, article_claims|
  article = articles[article_id]
  facts = article_claims.map { |c| claim_facts[c.id] }
  tier_counts = facts.group_by { |f| f[:tier] }.transform_values(&:size)

  sentences = article_claims.map(&:sentence)
  unique_sentences = sentences.uniq
  refs_per_sentence_counts = sentences.tally.values

  article_alerts = article_claims.map(&:alert_id).compact.uniq.map { |id| alerts[id] }.compact
  online = facts.count { |f| f[:tier] != 'offline' && f[:host] }
  hosts = facts.filter_map { |f| f[:host] }

  {
    'article_id' => article_id,
    'article_title' => article&.title&.tr('_', ' ') || article_claims.first.article_title,
    'article_url' => article&.url,
    'quality_rating' => article&.rating,
    'average_views' => article&.average_views&.round(1),
    'article_deleted' => article&.deleted ? 'yes' : nil,

    'subject' => article_claims.first.subject,
    'discipline' => discipline_for(article_claims.first.subject),
    'courses' => article_claims.map(&:source_course_id).compact.uniq
                              .filter_map { |id| courses[id]&.slug }.join('; '),
    'revision_count' => article_claims.map(&:mw_rev_id).compact.uniq.size,
    'latest_rev_timestamp' => article_claims.filter_map(&:mw_rev_timestamp).max,
    'diff_urls' => article_alerts.map(&:url).join(' '),
    'pangram_urls' => article_alerts.filter_map(&:pangram_url).join(' '),

    'max_fraction_ai_generated' => article_alerts.filter_map(&:fraction_ai_generated).max&.round(3),
    'max_ai_likelihood' => article_alerts.filter_map(&:max_ai_likelihood).max&.round(3),
    'predicted_llm' => article_alerts.filter_map(&:predicted_llm).uniq.join('; '),
    'chars_added_after_alert' => article_alerts.sum(&:characters_added_after_alert),

    'claim_count' => article_claims.size,
    'sentence_count' => unique_sentences.size,
    'distinct_sources' => article_claims.filter_map(&:source_url).uniq.size,
    'refs_per_sentence' => (article_claims.size.to_f / unique_sentences.size).round(2),
    'max_refs_one_sentence' => refs_per_sentence_counts.max,

    'claims_with_url' => article_claims.count { |c| c.source_url.present? },
    'offline_sources' => tier_counts['offline'].to_i,
    'pct_offline' => pct(tier_counts['offline'].to_i, article_claims.size),
    'access_open' => tier_counts['open'].to_i,
    'access_paywalled' => tier_counts['paywalled'].to_i,
    'access_abstract_only' => tier_counts['abstract_only'].to_i,
    'access_doi_redirect' => tier_counts['doi_redirect'].to_i,
    'access_unclassified' => tier_counts['unclassified'].to_i,
    'pct_open_of_all' => pct(tier_counts['open'].to_i, article_claims.size),
    'pct_open_of_online' => pct(tier_counts['open'].to_i, online),
    'claims_with_archive_url' => article_claims.count { |c| c.archive_url.present? },
    'distinct_domains' => hosts.uniq.size,
    'top_domains' => hosts.tally.sort_by { |_h, n| -n }.first(5)
                          .map { |h, n| "#{h} (#{n})" }.join('; '),

    'weak_source_claims' => hosts.count { |h| WEAK_SOURCE_DOMAINS.include?(h) },
    'mean_sentence_chars' => (unique_sentences.sum(&:length).to_f /
                              unique_sentences.size).round,
    'short_sentences' => unique_sentences.count { |s| s.length < SHORT_SENTENCE_CHARS },
    'pct_short_sentences' => pct(unique_sentences.count { |s| s.length < SHORT_SENTENCE_CHARS },
                                 unique_sentences.size),
    'pct_sentences_with_number' => pct(unique_sentences.count { |s| s.match?(/\d/) },
                                       unique_sentences.size),
    'repeated_sentence_claims' => article_claims.size - unique_sentences.size,
    'citation_stuffing' => refs_per_sentence_counts.max >= STUFFING_THRESHOLD ? 'yes' : nil,

    'topic_override' => nil,
    'access_spot_check' => nil,
    'content_quality' => nil,
    'include' => nil,
    'reviewer_notes' => nil
  }
end

# Best candidates first. The absolute count of open-access claims leads, because
# an article with one readable source out of one is worse rollout material than
# one with fifteen out of twenty; the share breaks ties.
rows.sort_by! { |r| [-r['access_open'], -(r['pct_open_of_all'] || 0)] }

article_path = File.join(DATA_DIR, 'fv_article_inventory.csv')
CSV.open(article_path, 'wb') do |csv|
  csv << ARTICLE_HEADERS
  rows.each { |row| csv << ARTICLE_HEADERS.map { |h| row[h] } }
end
puts "Wrote #{rows.size} article rows to #{article_path}"

# --- claim detail -------------------------------------------------------------

CLAIM_HEADERS = %w[
  claim_id article_id article_title subject discipline mw_rev_id sentence_chars
  sentence cite_text source_url source_domain access_tier offline_source
  archive_url ref_id
].freeze

claim_path = File.join(DATA_DIR, 'fv_claim_detail.csv')
CSV.open(claim_path, 'wb') do |csv|
  csv << CLAIM_HEADERS
  claims.sort_by { |c| [c.article_title.to_s, c.id] }.each do |claim|
    facts = claim_facts[claim.id]
    csv << [
      claim.id, claim.article_id, claim.article_title&.tr('_', ' '), claim.subject,
      discipline_for(claim.subject), claim.mw_rev_id, claim.sentence.length,
      claim.sentence, claim.cite_text, claim.source_url, facts[:host], facts[:tier],
      claim.offline_source? ? 'yes' : nil, claim.archive_url, claim.ref_id
    ]
  end
end
puts "Wrote #{claims.size} claim rows to #{claim_path}"

# --- summary ------------------------------------------------------------------

puts "\nDiscipline spread (articles / claims):"
rows.group_by { |r| r['discipline'] }
    .transform_values { |rs| [rs.size, rs.sum { |r| r['claim_count'] }] }
    .sort_by { |_d, (_a, c)| -c }
    .each { |d, (a, c)| puts format('  %-16s %4d articles  %5d claims', d, a, c) }

puts "\nAccess tier across all claims:"
totals = claim_facts.values.group_by { |f| f[:tier] }.transform_values(&:size)
(ACCESS_TIERS + ['offline']).each do |tier|
  puts format('  %-14s %5d  (%s%%)', tier, totals[tier].to_i,
              pct(totals[tier].to_i, claims.size))
end
