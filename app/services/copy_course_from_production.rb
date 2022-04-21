# frozen_string_literal: true

require 'net/http'

class CopyCourseFromProduction
  attr_reader :course, :course_data, :home_wiki

  def initialize(url)
    @course = make_copy_of(url)
  end

  private

  def make_copy_of(url)
    @copied_data = get_main_course_data(url)

    add_course(@copied_data)
    add_user_to_course(url)

    @course
  end

  def get_main_course_data(url)
    # Get the main course data
    @course_data = JSON.parse(Net::HTTP.get(URI(url + '/course.json')))['course']
    # Extract the attributes we want to copy
    params_to_copy = %w[school title term description start end subject slug timeline_start
                        timeline_end type flags]
    copied_data = {}
    params_to_copy.each { |p| copied_data[p] = @course_data[p] }
    @home_wiki = Wiki.get_or_create(language: @course_data['home_wiki']['language'],
                                    project: @course_data['home_wiki']['project'])
    copied_data['home_wiki_id'] = @home_wiki.id
    copied_data['passcode'] = 'passcode' # set an arbitrary passcode
    copied_data
  end

  def add_course(copied_data)
    # Create the course
    @course = Course.create!(
      copied_data
    )
    # Add the tracked wikis
    @course_data['wikis'].each do |wiki_hash|
      wiki = Wiki.get_or_create(language: wiki_hash['language'],
                                project: wiki_hash['project'])
      next if wiki.id == @home_wiki.id # home wiki was automatically added already
      @course.wikis << wiki
    end
  end

  def add_user_to_course(url)
    # Get the user list
    user_data = JSON.parse(Net::HTTP.get(URI(url + '/users.json')))['course']['users']
    # Add the users to the course
    user_data.each do |user_hash|
      user = User.find_or_create_by!(username: user_hash['username'])
      CoursesUsers.create!(user_id: user.id, role: user_hash['role'], course_id: @course.id)
    end
  end
end
