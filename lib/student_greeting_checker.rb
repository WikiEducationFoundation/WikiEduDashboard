# frozen_string_literal: true

# Checks which students have and haven't been greeted by a content expert.
class StudentGreetingChecker
  def self.check_all_ungreeted_students
    new.check_all_ungreeted_students
  end

  def initialize
    @greeters = User.where(greeter: true)
  end

  def check_all_ungreeted_students
    Course.strictly_current.each do |course|
      wiki = course.home_wiki
      course.students.ungreeted.each do |student|
        check(student, wiki)
      end
    end
  end

  def check(student, wiki)
    Check.new(student, wiki, @greeters).update_greeting_status
  end

  # Checks a single student to see if they are actually ungreeted, and updates
  # their greeted attribute if so.
  class Check
    def initialize(student, wiki, greeters)
      @student = student
      @wiki = wiki
      @all_greeters = greeters
    end

    def update_greeting_status
      return if talk_page_blank?
      contributor_names = contributors_to_page(@student.talk_page)
      return if (@all_greeters.pluck(:username) & contributor_names).empty?
      # Mark student as greeted if a greeter has already edited their talk page
      @student.update_attributes(greeted: true)
    end

    private

    def talk_page_blank?
      # Non-existent pages will return '', but API errors will return nil
      WikiApi.new(@wiki).get_page_content(@student.talk_page) == ''
    end

    def contributors_to_page(page_title)
      contributors_response = WikiApi.new(@wiki).query contributors_query(page_title)
      return if contributors_response.nil?
      # TODO: Add exception handling for unexpected response data.
      # Currently, that will just cause a NoMethodError, which is okay but not
      # optimal, because it will likely break a rake task. But it's at the end
      # of the rake batch anyway, so it's not a huge deal.
      contributors = contributors_response.data['pages'].values[0]['contributors']
      # If there are no non-anonymous contributors, the page exists but will
      # return no 'contributors' data.
      return [] if contributors.nil?
      contributor_usernames = contributors.map { |user| user['name'].tr(' ', '_') }
      contributor_usernames
    end

    def contributors_query(page_title)
      { prop: 'contributors',
        titles: page_title,
        pclimit: 500 }
    end
  end
end
