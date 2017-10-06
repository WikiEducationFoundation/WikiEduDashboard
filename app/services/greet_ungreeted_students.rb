# frozen_string_literal: true

require "#{Rails.root}/lib/student_greeting_checker"

class GreetUngreetedStudents
  def initialize(course, greeter)
    @course = course
    @greeter = greeter
    @wiki = @course.home_wiki
    @greeting_checker = StudentGreetingChecker.new
    greet_ungreeted
  end

  private

  def greet_ungreeted
    @course.students.where(greeted: false).each do |student|
      @greeting_checker.check(student, @wiki) # update greeted status
      next if student.greeted
      greet(student)
    end
  end

  def greet(student)
    response_data = WikiEdits.new(@wiki)
                             .add_new_section(@greeter, student.talk_page, welcome_message)
    return unless response_data.dig('edit', 'result') == 'Success'
    student.update_attributes(greeted: true)
  end

  def welcome_message
    name = first_name(@greeter)
    { sectiontitle: I18n.t('application.greeting2'),
      text: "{{subst:#{ENV['dashboard_url']} welcome|name=#{name}}}",
      summary: I18n.t('application.greeting_extended') }
  end

  def first_name(user)
    name = user.real_name || user.username
    # Split on either whitespace or underscore, so that it works for usernames
    # like Ian_(Wiki Ed) too.
    name.split(/[\s_]/)[0]
  end
end
