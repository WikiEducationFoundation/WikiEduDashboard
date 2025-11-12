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