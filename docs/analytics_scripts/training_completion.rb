# frozen_string_literal: true

require 'csv'

campaign = Campaign.find_by(slug: 'spring_2016')

# CSV of all assigned training modules for courses in the campaign:
# course slug, training module, due date

courses = campaign.courses
csv_data = []
courses.each do |course|
  course.training_modules.each do |training_module|
    points = 0
    course.blocks.each do |block|
      module_ids = block.training_module_ids
      next unless module_ids.include?(training_module.id)
      points = block.points
    end
    due_date = TrainingModuleDueDateManager.new(course: course, training_module: training_module)
                                           .computed_due_date
    csv_data << [course.slug, training_module.slug, due_date, points]
  end
end

CSV.open('/home/sage/spring_2016_training_due_dates.csv', 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end

# CSV of all training module progress for students in the campaign:
# username, training module, last slide completed, module completion date

user_csv_data = []
campaign.students.each do |student|
  student.training_modules_users.each do |tmu|
    user_csv_data << [student.username,
                      tmu.training_module.slug,
                      tmu.last_slide_completed,
                      tmu.completed_at]
  end
end

CSV.open('/home/sage/spring_2016_student_training_completion.csv', 'wb') do |csv|
  user_csv_data.each do |line|
    csv << line
  end
end


TrainingModule.all.each do |tm|
  pp tm.name
  completion_csv = [['module', 'module_id', 'user_id', 'started_at', 'completed_at', 'completion_time_in_seconds']]
  TrainingModulesUsers.where(training_module: tm).where.not(completed_at: nil).where.not(created_at: nil).each do |tmu|
    completion_csv << [tm.name, tm.id, tmu.user_id, tmu.created_at, tmu.completed_at, tmu.completed_at - tmu.created_at]
  end
  CSV.open("/home/sage/training_completion_times_#{tm.name}_#{tm.id}.csv", 'wb') do |csv|
    completion_csv.each do |line|
      csv << line
    end
  end
end

# CSV of training activity for Wikimedia Germany's training modules

module_ids = [40001, 40002, 40003, 40004]


csv_data = [['username', 'training_module', 'last_slide_completed', 'module_completion_date', 'started_at', 'last_slide_completed_at']]

module_ids.each do |m_id|
  tm = TrainingModule.find(m_id)
  tmus = TrainingModulesUsers.where(training_module_id: m_id)
  tmus.each do |tmu|
    csv_data << [tmu.user&.username, tm.slug, tmu.last_slide_completed, tmu.completed_at, tmu.created_at, tmu.updated_at]
  end
end

CSV.open('/home/ragesoss/wmde_training_data_2022-02.csv', 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end

# CSV of all training activity on P&E Dashboard

csv_data = [['username', 'training_module', 'last_slide_completed', 'module_completion_date', 'started_at', 'last_slide_completed_at']]

TrainingModule.all.each do |tm|
  tmus = TrainingModulesUsers.where(training_module_id: tm.id).includes(:user)
  tmus.each do |tmu|
    csv_data << [tmu.user&.username, tm.slug, tmu.last_slide_completed, tmu.completed_at, tmu.created_at, tmu.updated_at]
  end
end

CSV.open('/home/ragesoss/training_completion_data_2024-03-11.csv', 'wb') do |csv|
  csv_data.each do |line|
    csv << line
  end
end