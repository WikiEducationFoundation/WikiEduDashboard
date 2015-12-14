class StudentGreeter
  def self.greet_all_ungreeted_students
    new.greet_all_ungreeted_students
  end

  def initialize
    @greeters = User.where(greeter: true)
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

  def greet_if_ungreeted(student, greeter)
    # return if student.greeted
    if talk_page_blank? student
      greet(student, greeter)
      return
    end
    return if a_greeter_already_posted?(student)
    greet(student, greeter)
  end

  def talk_page_blank?(student)
    Wiki.get_page_content(student.talk_page).nil?
  end

  def a_greeter_already_posted?(student)
    contributor_ids = ids_of_contributors_to_page(student.talk_page)
    return true unless (@greeters.pluck(:id) & contributor_ids).empty?
    false
  end

  def ids_of_contributors_to_page(page_title)
    contributors_response = Wiki.query contributors_query(page_title)
    # TODO: exception handling for unexpected response data
    pp contributors_response.data['pages'].values[0]
    contributors = contributors_response.data['pages'].values[0]['contributors']
    contributor_ids = contributors.map { |user| user['userid'] }
    contributor_ids
  end

  def contributors_query(page_title)
    { prop: 'contributors',
      titles: page_title,
      pclimit: 500 }
  end

  def welcome_message(greeter)
    name = first_name(greeter)
    { sectiontitle: 'Welcome!',
      text: "{{subst:#{ENV['dashboard_url']} welcome|name=#{name}}}",
      summary: 'Welcome to Wikipedia' }
  end

  def first_name(user)
    name = user.real_name || user.wiki_id
    name.split(/[\s_]/)[0]
  end

  def greet(student, greeter)
    message = welcome_message(greeter)
    response_data = WikiEdits.notify_user(greeter, student, message)
    pp response_data
    return if response_data['edit'].nil?
    return unless response_data['edit']['result'] == 'Success'
    student.update_attributes(greeted: true)
  end
end
