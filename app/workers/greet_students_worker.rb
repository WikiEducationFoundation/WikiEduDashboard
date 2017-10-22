# frozen_string_literal: true

class GreetStudentsWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.schedule_greetings(course, greeter)
    perform_async(course.id, greeter.id)
  end

  def perform(course_id, greeter_id)
    course = Course.find(course_id)
    greeter = User.find(greeter_id)
    GreetUngreetedStudents.new(course, greeter)
  end
end
