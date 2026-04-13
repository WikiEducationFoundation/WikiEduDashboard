# Script for getting spreadsheet data for investigating AiEditAlerts

same_user_repeats = AiEditAlert.all.select { |a| a.details.key? :prior_alert_for_user }

data = [['alert id', 'username', 'page', 'pangram', 'timestamp', 'prior page', 'prior pangram', 'prior timestamp']]
same_user_repeats.each do |a|
  # alert id, username, page, pangram link, timestamp, prior alert page, prior alert pangram link, prior alert timestamp
  prior_alert = AiEditAlert.find a.prior_alert_id_for_user

  data << [a.id, a.user.username, a.article_title, a.pangram_url, a.created_at, prior_alert.article_title, prior_alert.pangram_url, prior_alert.created_at]
end

CSV.open("/home/sage/ai_repeat_users.csv", 'wb') do |csv|
  data.each do |line|
    csv << line
  end
end

# Mainspace alerts with subsequent edits
# to analyze how students responded in mainspace after an alert.

fall_2025 = Campaign.find_by_slug 'fall_2025'
fall_alerts = AiEditAlert.where(course_id: fall_2025.courses.pluck(:id))
fall_mainspace_alerts = fall_alerts.select { |a| a.page_type == :mainspace }

data = [['article', 'course', 'user', 'timestamp', 'pangram_report', 'latest_edit_timestamp', 'days_edited', 'article_viewer']]
fall_mainspace_alerts.each do |a|
  acts = ArticleCourseTimeslice.where(course_id: a.course_id, article_id: a.article_id)
  article = Article.find(a.article_id)
  course = Course.find(a.course_id)
  user = User.find(a.user_id)
  article_viewer = "https://dashboard.wikiedu.org/courses/#{course.slug}/articles/edited?showArticle=#{article.id}"
  data << [article.full_title, course.slug, user.username, a.created_at, a.pangram_url, acts.last&.start, acts.count, article_viewer]
end

CSV.open("/home/sage/ai_mainspace_alerts_fall_2025.csv", 'wb') do |csv|
  data.each do |line|
    csv << line
  end
end

# All AI alerts with feedback

feedbacks = AiEditAlert.all.select(&:followup?)
data = [%w[alert_id alert_timestamp page_type AI_how_used AIs_used AI_other user_for used_for_other additional_context timestamp pangram_report]]

feedbacks.each do |alert|
  puts alert.id
  entry = alert.followup_student
  next unless entry
  data << [alert.id, alert.created_at, alert.page_type, entry[:AI_how_used], entry[:AIs_used], entry[:AIs_other], entry[:used_for], entry[:used_for_other], entry[:additional_context], entry[:timestamp], alert.pangram_url]
end

CSV.open("/home/sage/ai_alert_feedbacks.csv", 'wb') do |csv|
  data.each do |line|
    csv << line
  end
end
