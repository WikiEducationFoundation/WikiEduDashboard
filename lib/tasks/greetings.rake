namespace :greetings do
  desc 'Post welcome messages to ungreeted students'
  task welcome_students: 'batch:setup_logger' do
    Rails.logger.debug 'Greeting students in classes with greeters'
    StudentGreeter.greet_all_ungreeted_students
  end
end
