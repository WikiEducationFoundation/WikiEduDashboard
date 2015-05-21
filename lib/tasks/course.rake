require "#{Rails.root}/lib/importers/course_importer"

namespace :course do
  desc 'Update courses and course users'
  task update_courses: 'batch:setup_logger' do
    Rails.logger.debug 'Updating all courses'
    CourseImporter.update_all_courses
  end

  desc 'Pull data for all courses and course users'
  task update_courses_all_time: 'batch:setup_logger' do
    Rails.logger.debug 'Pulling data for all courses on Wikipedia'
    CourseImporter.update_all_courses(true)
  end
end
