# frozen_string_literal: true

require "#{Rails.root}/lib/chat/rocket_chat"

#= Enables chat features for a course and adds all participants to course chat channel
class EnableCourseChat
  def initialize(course)
    @course = course
    enable
  end

  private

  def enable
    set_course_flag
    add_users_to_course_chat_channel
  end

  def set_course_flag
    @course.flags[:enable_chat] = true
    @course.save
  end

  def add_users_to_course_chat_channel
    @course.users.each do |user|
      RocketChat.new(user: user, course: @course).add_user_to_course_channel
    end
  end
end
