CSV.open("/home/sage/ticket_status.csv", 'wb') do |csv|
  csv << ['opened', 'updated', 'time_difference', 'status', 'message_count', 'owner']
  TicketDispenser::Ticket.all.includes(:owner).each do |ticket|
    csv << [ticket.created_at, ticket.updated_at, ticket.updated_at - ticket.created_at, ticket.status, ticket.messages.count, ticket.owner&.username]
  end
end

CSV.open("/home/sage/need_help_ticket_data.csv", 'wb') do |csv|
  csv << ['opened', 'updated', 'time_difference', 'status', 'message_count', 'owner', 'first_message']
  TicketDispenser::Ticket.all.includes(:owner, :messages).each do |ticket|
    next unless ticket.messages.first.details[:subject]&.include? 'NeedHelpAlert'
    csv << [ticket.created_at, ticket.updated_at, ticket.updated_at - ticket.created_at, ticket.status, ticket.messages.count, ticket.owner&.username, ticket.messages.first.details[:subject], ticket.messages.first.content]
  end
end

CSV.open("/home/sage/sandbox_need_help_data.csv", 'wb') do |csv|
  csv << ['created_at', 'message']
  NeedHelpAlert.all.each_cons(2) do |first_message, second_message|
    next if first_message.message == second_message.message
    next unless first_message.message.include?('sandbox')
    csv << [first_message.created_at, first_message.message]
  end
end

CSV.open("/home/sage/assignment_need_help_data.csv", 'wb') do |csv|
  csv << ['created_at', 'message']
  NeedHelpAlert.all.each_cons(2) do |first_message, second_message|
    next if first_message.message == second_message.message
    next unless first_message.message.include?('assignment')
    csv << [first_message.created_at, first_message.message]
  end
end

date = '2016-06-01'.to_datetime
CSV.open("/home/sage/need_help_trend_monthly.csv", 'wb') do |csv|
  csv << ['week', 'active_courses', 'need_help_count']
  56.times do
    puts date
    next_date = date + 1.month
    course_count = Course.where('start < ?', date).where('end > ?', date).count
    help_count = NeedHelpAlert.where('created_at > ?', date).where('created_at < ?', next_date).count
    csv << [date.to_date, course_count, help_count]
    date = next_date
  end
end

date = '2018-01-01'.to_datetime
CSV.open("/home/sage/student_need_help_trend_monthly.csv", 'wb') do |csv|
  csv << ['week', 'active_courses', 'need_help_count']
  36.times do
    puts date
    next_date = date + 1.month
    course_count = ClassroomProgramCourse.where('courses.start < ?', next_date).where('courses.end > ?', date).includes(:campaigns).where('campaigns.id IS NOT NULL').references(:campaigns).count
    help_count = NeedHelpAlert.where('alerts.created_at > ?', date).where('alerts.created_at < ?', next_date).includes(:user).where(users: { permissions: 0 }).count
    csv << [date.to_date, course_count, help_count]
    date = next_date
  end
end

date = '2018-01-01'.to_datetime
CSV.open("/home/sage/instructor_need_help_trend_monthly.csv", 'wb') do |csv|
  csv << ['week', 'active_courses', 'need_help_count']
  36.times do
    puts date
    next_date = date + 1.month
    course_count = ClassroomProgramCourse.where('courses.start < ?', next_date).where('courses.end > ?', date).includes(:campaigns).where('campaigns.id IS NOT NULL').references(:campaigns).count
    help_count = NeedHelpAlert.where('alerts.created_at > ?', date).where('alerts.created_at < ?', next_date).includes(:user).where(users: { permissions: 2 }).count
    csv << [date.to_date, course_count, help_count]
    date = next_date
  end
end

sandbox_alerts = []
NeedHelpAlert.all.each_cons(2) do |first_message, second_message|
  next if first_message.message == second_message.message
  next unless first_message.message.include?('sandbox')
  sandbox_alerts << first_message
end
date = '2016-06-01'.to_datetime
55.times do
  prior_alerts = sandbox_alerts.select { |a| a.created_at < date }
  puts "#{date}, #{prior_alerts.count}"
  sandbox_alerts = sandbox_alerts - prior_alerts
  date = date + 1.month
end


assignment_alerts = []
NeedHelpAlert.all.each_cons(2) do |first_message, second_message|
  next if first_message.message == second_message.message
  next unless first_message.message.include?('assignment')
  assignment_alerts << first_message
end
date = '2016-06-01'.to_datetime
55.times do
  prior_alerts = assignment_alerts.select { |a| a.created_at < date }
  puts "#{date}, #{prior_alerts.count}"
  assignment_alerts = assignment_alerts - prior_alerts
  date = date + 1.month
end

assignment_alerts = []
NeedHelpAlert.all.each_cons(2) do |first_message, second_message|
  next if first_message.message == second_message.message
  next unless first_message.message.include?('where')
  assignment_alerts << first_message
end
date = '2016-06-01'.to_datetime
55.times do
  prior_alerts = assignment_alerts.select { |a| a.created_at < date }
  puts "#{date}, #{prior_alerts.count}"
  assignment_alerts = assignment_alerts - prior_alerts
  date = date + 1.month
end
