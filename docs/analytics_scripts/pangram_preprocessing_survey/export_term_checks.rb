# Paste into a production Rails console. Read-only.
#
# Exports every production Pangram check for this term's courses, one JSON object per
# line, to ~/pangram_checks_fall_2026.jsonl.gz. Stored results hold no text (the
# parser strips it), so each row carries the public Pangram share link, which returns
# the exact text that was scored. The survey fetches texts locally from those links.
#
# Each row: revision and page identity, page type (as AiEditAlert classifies titles),
# detector summary, every window's offsets and scores, and, for rows that became
# alerts, the alert id, whether it was resolved, and the student's structured
# follow-up answers (no free text, no usernames).

require 'zlib'

TERM_SLUG = 'fall_2026'
OUT_PATH = File.expand_path("~/pangram_checks_#{TERM_SLUG}.jsonl.gz")

campaign = Campaign.find_by!(slug: TERM_SLUG)
course_slugs = campaign.courses.pluck(:id, :slug).to_h
wikis = Wiki.all.to_h { |w| [w.id, "#{w.language}.#{w.project}"] }

scores = RevisionAiScore.where(course_id: course_slugs.keys,
                               check_origin: [nil, RevisionAiScore::COURSE_UPDATE_ORIGIN])
                        .where(check_type: [RevisionAiScore::PANGRAM_V3_KEY,
                                            RevisionAiScore::PANGRAM_V4_KEY])
articles = Article.where(id: scores.distinct.pluck(:article_id)).index_by(&:id)
alerts = AiEditAlert.where(revision_id: scores.pluck(:revision_id)).index_by(&:revision_id)

# The same title-based page types alerts use, for checks that never became alerts.
page_type = ->(title) { AiEditAlert.new(details: { article_title: title }).page_type }

followup_fields = %i[AI_how_used AIs_used used_for timestamp]
alert_fields = lambda do |alert|
  return {} unless alert
  student = alert.followup_student&.slice(*followup_fields)
  { alert_id: alert.id, alert_created_at: alert.created_at, resolved: alert.resolved,
    email_sent: alert.email_sent_at.present?, student_followup: student,
    other_followups: alert.followup_non_student.size }
end

window_row = lambda do |w|
  [w['start_index'], w['end_index'], w['word_count'], w['ai_assistance_score'],
   w['label'], w['confidence'], w['humanizer_score']]
end

counts = Hash.new(0)
Zlib::GzipWriter.open(OUT_PATH) do |gz|
  scores.find_each do |s|
    d = s.details || {}
    article = articles[s.article_id]
    title = article&.full_title
    alert = alerts[s.revision_id]
    row = {
      revision_id: s.revision_id, wiki: wikis[s.wiki_id], course: course_slugs[s.course_id],
      article_id: s.article_id, mw_page_id: article&.mw_page_id, title:,
      page_type: title && page_type.call(title),
      revision_datetime: s.revision_datetime, checked_at: s.created_at,
      check_type: s.check_type, version: d['version'], error: d['error'],
      max_ai: s.max_ai_likelihood, avg_ai: s.avg_ai_likelihood,
      prediction_short: d['prediction_short'], headline: d['headline'],
      fraction_ai: d['fraction_ai'], fraction_mixed: d['fraction_mixed'],
      word_count: d['word_count'], share_link: d['dashboard_link'],
      windows: (d['windows'] || []).map(&window_row)
    }.merge(alert_fields.call(alert))
    gz.puts(row.to_json)
    counts[[s.check_type, d['version'], row[:page_type], alert ? :alert : :no_alert]] += 1
  end
end

puts "Wrote #{OUT_PATH}"
puts '[check_type, version, page_type, alert?] => rows'
pp counts.sort_by { |k, _| k.map(&:to_s) }.to_h
nil
