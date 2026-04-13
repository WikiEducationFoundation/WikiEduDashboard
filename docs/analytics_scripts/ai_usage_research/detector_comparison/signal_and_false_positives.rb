# Looking at a sample of new and expanded articles from pre-chatGPT and beyond
# Find latest student revision of each, get plaintext, then run it through
# all 4 models and document signal from each.

require_relative "./cumulative_diff"

terms = %w[spring_2021 fall_2021 spring_2022 fall_2022 spring_2023 fall_2023 spring_2024 fall_2024 spring_2025 fall_2025]
campaigns = terms.map { |term| Campaign.find_by_slug term }

SAMPLE_PER_TERM = 100

ac_headers = %w[term course article character_sum new_article references_count cumulative_diff]

data = [ac_headers]
campaigns.each do |campaign|
  puts campaign.slug
  # edited articles with at least 3000 characters added
  arts = ArticlesCourses.where(course: campaign.courses).where('character_sum > 3000').sample SAMPLE_PER_TERM
  arts.each do |ac|
    diff_url = CumulativeDiff.new(ac).generate_diff_url
    data << [campaign.slug, ac.course.slug, ac.article.title, ac.character_sum, ac.new_article, ac.references_count, diff_url]
  end
end

CSV.open("/home/sage/sampled_cumulative_diffs_by_term.csv", 'wb') do |csv|
  data.each { |line| csv << line }
end

# Doing these locally
require_dependency "#{Rails.root}/lib/utils/wiki_url_parser"
require_dependency "#{Rails.root}/lib/pangram_api"
require_dependency "#{Rails.root}/lib/originality_api"
\
csv_text = File.read "/home/ragesoss/Downloads/sampled_cumulative_diffs_by_term.csv"
csv = CSV.parse(csv_text, headers: true)

en_wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
PANGRAM_V3_KEY = 'pangram_v3'
ORIGINALITY_TURBO_KEY = 'originality_turbo'
ORIGINALITY_ACADEMIC_KEY = 'originality_academic'
DETECTORS = {
  PANGRAM_V3_KEY => PangramApi.v3,
  ORIGINALITY_TURBO_KEY => OriginalityApi.turbo,
  ORIGINALITY_ACADEMIC_KEY => OriginalityApi.academic
}

ac_headers = %w[term course article character_sum new_article references_count cumulative_diff]
def ac_row(csv_row)
  [csv_row['term'], csv_row['course'], csv_row['article'], csv_row['character_sum'], csv_row['new_article'], csv_row['references_count'], csv_row['cumulative_diff']]
end


pangram_headers = %w[pangram_result fraction_ai fraction_ai_assisted fraction_human pangram_max_likelihood pangram_avg_likelihood pangram_report]
def pg_result_row(pg_result)
  window_likelihoods = pg_result['windows'].map { |window| window['ai_assistance_score'] }
  max_likelihood = window_likelihoods.max
  avg_likelihood = window_likelihoods.sum.fdiv(window_likelihoods.count)
  [pg_result['prediction_short'], pg_result['fraction_ai'], pg_result['fraction_ai_assisted'], pg_result['fraction_human'], max_likelihood, avg_likelihood, pg_result['dashboard_link']]
end

o_ai_turbo_headers = %w[o_ai_turbo_result o_ai_turbo_ai_confidence o_ai_turbo_max_fake o_ai_turbo_avg_fake o_ai_turbo_report]
o_ai_academic_headers = %w[o_ai_academic_result o_ai_academic_ai_confidence o_ai_academic_max_fake o_ai_academic_avg_fake o_ai_academic_report]
def originality_result_row(oai_result)
  window_scores = oai_result['results']['ai']['blocks'].map { |b| b['result']['fake'] }
  result = oai_result['results']['ai']['classification']['AI']
  confidence = oai_result['results']['ai']['confidence']['AI']
  max_signal = window_scores.max
  avg_signal = window_scores.sum.fdiv(window_scores.count)
  report = oai_result['results']['properties']['publicLink']
  [result, confidence, max_signal, avg_signal, report]
rescue NoMethodError => e
  pp oai_result
  raise e
end

headers = ac_headers + pangram_headers + o_ai_turbo_headers + o_ai_academic_headers
i = 0
local_data = [headers]
csv.each do |row|
  i += 1
  puts i
  next unless i > 972
  diff = row['cumulative_diff']
  puts diff
  url_parser = WikiUrlParser.new(diff)
  diff_rev = url_parser.diff
  oldid_rev = url_parser.oldid
  if oldid_rev.blank?
    local_data << ac_row(row)
    next
  end
  plaintext = if (diff_rev && oldid_rev)
                GetRevisionPlaintext.new(diff_rev, en_wiki, diff_mode: true, from_rev: oldid_rev).plain_text
              else
                GetRevisionPlaintext.new(oldid_rev, en_wiki, diff_mode: false).plain_text
              end
  if plaintext.length.zero?
    local_data << ac_row(row)
    next
  end
  puts 'pg'
  pg_result = DETECTORS[PANGRAM_V3_KEY].inference plaintext
  puts 'o turbo'
  ai_turbo_result = DETECTORS[ORIGINALITY_TURBO_KEY].inference plaintext
  puts 'o academic'
  ai_academic_result = DETECTORS[ORIGINALITY_ACADEMIC_KEY].inference plaintext
  local_data << ac_row(row) + pg_result_row(pg_result) + originality_result_row(ai_turbo_result) + originality_result_row(ai_academic_result)
rescue MediawikiApi::ApiError
  local_data << ac_row(row)
  next
end

CSV.open("/home/sage/WikiEduDashboard/docs/analytics_scripts/ai_usage_research/detector_comparison/sampled_cumulative_diffs_by_term_1000.csv", 'wb') do |csv|
  local_data.each { |line| csv << line }
end
