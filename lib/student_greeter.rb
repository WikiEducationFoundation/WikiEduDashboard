class StudentGreeter
  def new
    @greeters = User.find_by(wiki_id: 'Ragesock') # User.where(greeter: true)
  end

  private

  def greet_all_ungreeted_students
    courses = Course.strictly_current
    courses.each do |course|
      nonstudents_in_course = course.nonstudents
      possible_greeters = @greeters & nonstudents_in_course
      next if possible_greeters.empty?
      greeter = possible_greeters[0]
      course.students_without_nonstudents.each do |student|
        greet_if_ungreeted(student, greeter)
      end
    end
  end

  def self.greet_if_ungreeted(student, greeter)
    return if student.greeted
    if talk_page_blank? student
      greet student
      return
    end
    # TODO: check whether any of the greeters have edited the talk page. return if so.
    greet student
  end

  def talk_page_blank?(student)
    Wiki.get_page_content(student.talk_page).nil?
  end

  def welcome_message(greeter)
    # TODO get first name from real name, add to subst template
  end

  def self.greet(student, greeter)
    response_data = WikiEdits.notify_users(greeter, [student], welcome_message)

    return if response_data['edit'].nil
    return unless response_data['edit']['result'] == 'Success'
    student.update_attributes(greeted: true) if result
  end
end
