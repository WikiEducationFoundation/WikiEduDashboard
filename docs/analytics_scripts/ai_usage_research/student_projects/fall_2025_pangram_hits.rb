# script for collecting a dataset of pangram-based AI alerts for
# student research project

# First get the alerts from the production server.
campaign = Campaign.find_by_slug 'fall_2025'
alerts = campaign.alerts.where(type: 'AiEditAlert').includes(:article)

alerts_csv = [['alert_id', 'revision_id', 'page_type']]
alerts.each do |alert|
  alerts_csv << [alert.id, alert.revision_id, alert.page_type]
end

CSV.open('/home/sage/fall_2025_ai_alerts.csv', 'wb') do |csv|
  alerts_csv.each { |line| csv << line }
end

# Then use that in a dev environment to get the plaintext

en_wiki = Wiki.find(1)
csv_data = [['revision_id', 'page_type', 'plain_text']]

CSV.foreach('fall_2025_ai_alerts.csv', headers: true) do |row|
  puts row
  rev_id = row[1]
  pt = GetRevisionPlaintext.new(rev_id, en_wiki)
  plain_text = pt.plain_text
  page_type = row[2]
  csv_data << [rev_id, page_type, plain_text]
end

CSV.open('fall_2025_ai_plain.csv', 'wb') do |csv|
  csv_data.each { |line| csv << line }
end
