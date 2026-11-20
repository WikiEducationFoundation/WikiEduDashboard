# Paste into a production Rails console. Read-only: summarizes the stored results of
# production Pangram checks, to see how often Pangram 4.1's humanizer flag sits
# behind an alert-level score (any window above 0.9, the CheckRevisionWithPangram
# threshold). Not every alert-level result has an alert: alerts also need an edit
# under 7 days old.

rows = RevisionAiScore.where(check_type: RevisionAiScore::PANGRAM_V4_KEY,
                             check_origin: [nil, RevisionAiScore::COURSE_UPDATE_ORIGIN])
                      .where.not(avg_ai_likelihood: nil)
                      .pluck(:revision_id, :created_at, :details)

puts '== Rows by Pangram version: [count, [first, last]]'
pp rows.group_by { |_, _, d| d['version'] }.transform_values { |rs| [rs.size, rs.map { |r| r[1] }.minmax] }

summarize = lambda do |version|
  rows.select { |_, _, d| d['version'] == version }.map do |rev, at, d|
    ws = d['windows'] || []
    hot = ws.select { |w| w['ai_assistance_score'].to_f > 0.9 }
    { rev:, at:, alert: hot.any?, hot: hot.size,
      hot_humanized: hot.count { |w| w['is_humanized'] },
      max_humanizer: ws.map { |w| w['humanizer_score'].to_f }.max.to_f,
      biggest_hot_window: hot.map { |w| w['word_count'].to_i }.max }
  end
end

%w[4.0 4.1].each do |version|
  checks = summarize.call(version)
  hot = checks.select { |r| r[:alert] }
  puts "== Pangram #{version} summary"
  pp({ checks: checks.size, alert_level: hot.size,
       checks_with_humanized_window: checks.count { |r| r[:max_humanizer] > 0.5 },
       alert_level_with_humanized_hot_window: hot.count { |r| r[:hot_humanized] > 0 },
       alert_level_only_humanized_hot_windows: hot.count { |r| r[:hot_humanized] == r[:hot] },
       max_humanizer_by_tenth: checks.group_by { |r| r[:max_humanizer].floor(1) }
                                     .transform_values(&:size).sort.to_h })
end

alerts = summarize.call('4.1').select { |r| r[:alert] }
flagged = alerts.select { |r| r[:hot_humanized] > 0 }
alert_ids = AiEditAlert.where(revision_id: flagged.map { |r| r[:rev] }).pluck(:revision_id, :id).to_h
puts '== Pangram 4.1 humanizer-flagged alert-level results:'
puts '   [rev_id, alert_id, date, hot windows, humanized hot windows, max humanizer, biggest hot window words]'
flagged.each do |r|
  p [r[:rev], alert_ids[r[:rev]], r[:at].to_date, r[:hot], r[:hot_humanized],
     r[:max_humanizer].round(3), r[:biggest_hot_window]]
end

# The peer review that prompted this study. A re-run of the same text on 2026-11-16
# split it into 10 windows; this shows how the stored production result split it.
puts '== Stored windows for rev 1385856331: [words, score, confidence, humanized, humanizer score]'
stored = rows.find { |rev, _, _| rev == 1_385_856_331 }&.last || {}
p stored['version']
(stored['windows'] || []).each do |w|
  p [w['word_count'], w['ai_assistance_score'].to_f.round(3), w['confidence'], w['is_humanized'],
     w['humanizer_score'].to_f.round(3)]
end
nil
