class StudentGreeter
  def self.greet_all_ungreeted_students
    new.greet_all_ungreeted_students
  end

  def initialize
    @greeters = User.where(greeter: true)
  end

  def greet_all_ungreeted_students
    Course.strictly_current.each do |course|
      nonstudents_in_course = course.nonstudents
      # Only users who both have the greeter flag and are enrolled as nonstudents
      # are possible greeters for a class.
      possible_greeters = @greeters & nonstudents_in_course
      next if possible_greeters.empty?
      greeter = possible_greeters[0]
      course.students_without_nonstudents.ungreeted.each do |student|
        greet_if_really_ungreeted(student, greeter)
      end
    end
  end

  private

  # Just because a user is not flagged as greeted doesn't mean they haven't
  # actually been greeted.
  def greet_if_really_ungreeted(student, greeter)
    if talk_page_blank? student
      greet(student, greeter)
      return
    end
    return if a_greeter_already_posted?(student)
    greet(student, greeter)
  end

  def talk_page_blank?(student)
    WikiApi.get_page_content(student.talk_page).nil?
  end

  def a_greeter_already_posted?(student)
    contributor_ids = ids_of_contributors_to_page(student.talk_page)
    return false if (@greeters.pluck(:id) & contributor_ids).empty?
    # Mark student as greeted if a greeter has already edited their talk page
    student.update_attributes(greeted: true)
    true
  end

  def ids_of_contributors_to_page(page_title)
    contributors_response = WikiApi.query contributors_query(page_title)
    # TODO: Add exception handling for unexpected response data.
    # Currently, that will just cause a NoMethodError, which is okay but not
    # optimal, because it will likely break a rake task. But it's at the end
    # of the rake batch anyway, so it's not a huge deal.
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
    { sectiontitle: I18n.t("application.greeting2"),
      text: "{{subst:#{ENV['dashboard_url']} welcome|name=#{name}}}",
      summary: I18n.t("application.greeting_extended") }
  end

  def first_name(user)
    name = user.real_name || user.wiki_id
    # Split on either whitespace or underscore, so that it works for usernames
    # like Ian_(Wiki Ed) too.
    name.split(/[\s_]/)[0]
  end

  def greet(student, greeter)
    message = welcome_message(greeter)
    response_data = WikiEdits.notify_user(greeter, student, message)
    return if response_data['edit'].nil?
    return unless response_data['edit']['result'] == 'Success'
    student.update_attributes(greeted: true)
  end
end
