namespace :course do
  desc 'Update the participants for current courses'
  task :update_courses => :environment do
    logger.info "Updating all courses"
    Course.update_all_courses
  end
  task :update_participants => :environment do
    Course.update_participants
  end
end