# We had a period where all the revision datetimes were coming through as 1970 (ie, Unix epoch time zero).
# This is how I used RevisionAiScore records to recreate the AiEditAlerts that should have been created for those revisions.

# The first such record is RevisionAiScore 12256.
# There are 688 total, but one was a Pangram server error.
first_example = RevisionAiScore.find(12256)

scores = RevisionAiScore.where(revision_datetime: first_example.revision_datetime)
# 688 scores
scores = scores.select { |s| s.details['max_ai_likelihood'].present? }
# 687 scores

missing_alerts = scores.select { |s| s.details['max_ai_likelihood'] > 0.75 }
# 58 records

missing_alerts.reject! { |s| AiEditAlert.where(revision_id: s.revision_id).exists? }
# 58 records still

missing_alerts.each do |s|
  puts s.id
  pangram_details = {
    article_title: s.article.full_title.tr('_', ' '),
    pangram_prediction: s.details['prediction'],
    headline_result: s.details['headline'],
    average_ai_likelihood: s.details['avg_ai_likelihood'],
    max_ai_likelihood: s.details['max_ai_likelihood'],
    fraction_human_content: s.details['fraction_human'],
    fraction_ai_content: s.details['fraction_ai'],
    fraction_mixed_content: s.details['fraction_mixed'],
    window_likelihoods: s.details['window_likelihoods'],
    predicted_ai_window_count: s.details['window_likelihoods'].count { |likelihood| likelihood > 0.5 },
    pangram_share_link: s.details['dashboard_link'],
    pangram_version: s.details['version']
  }
  AiEditAlert.generate_alert_from_pangram(revision_id: s.revision_id,
                                          user_id: s.user_id,
                                          course_id: s.course_id,
                                          article_id: s.article_id,
                                          pangram_details: pangram_details)
end
