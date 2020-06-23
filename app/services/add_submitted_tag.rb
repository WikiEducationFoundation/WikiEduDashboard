# frozen_string_literal: true

#= Adds a tag to serve as the timestamp of when a course was submitted.
class AddSubmittedTag
  def initialize(course)
    @course = course
    add_tag
  end

  private

  def add_tag
    return if @course.tag? 'submitted'
    TagManager.new(@course).add(tag: 'submitted')
  end
end
