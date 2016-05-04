require "#{Rails.root}/lib/student_greeter"

namespace :greetings do
  desc 'Post welcome messages to ungreeted students'
  task welcome_students: :environment do
    Rails.logger.debug 'Greeting students in classes with greeters'
    StudentGreeter.greet_all_ungreeted_students
  end
end
