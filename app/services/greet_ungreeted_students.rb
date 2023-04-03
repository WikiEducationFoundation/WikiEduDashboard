# frozen_string_literal: true

require_dependency Rails.root.join('lib/student_greeting_checker')
require_dependency Rails.root.join('lib/wiki_course_edits')

class GreetUngreetedStudents
  def initialize(course, greeter)
    @course = course
    @greeter = greeter
    @wiki = @course.home_wiki
    return unless @wiki.edits_enabled?
    @greeting_checker = StudentGreetingChecker.new
    greet_ungreeted
  end

  private

  def greet_ungreeted
    @course.students.where(greeted: false).each do |student|
      # update greeted status
      @greeting_checker.check(student, @wiki)

      # add enrollment templates if not already present
      WikiCourseEdits.new(action: :enroll_in_course,
                          course: @course,
                          current_user: @greeter,
                          enrolling_user: student)

      next if student.greeted
      greet(student)
    end
  end

  def greet(student)
    response_data = WikiEdits.new(@wiki)
                             .add_new_section(@greeter, student.talk_page, welcome_message)
    return unless response_data.dig('edit', 'result') == 'Success'
    student.update(greeted: true)
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
