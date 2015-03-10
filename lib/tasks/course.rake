namespace :course do
  desc 'Update courses and course users'
  task update_courses: :environment do
    Rails.logger.info 'Updating all courses'
    Course.update_all_courses
  end

  desc 'Pull data for all courses and course users'
  task update_courses_all_time: :environment do
    Rails.logger.info 'Pulling data for all courses on Wikipedia'
    Course.update_all_courses(true)
  end
end