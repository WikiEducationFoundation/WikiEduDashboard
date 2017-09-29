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
      next if block.gradeable.nil?
      points = block.gradeable.points
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
