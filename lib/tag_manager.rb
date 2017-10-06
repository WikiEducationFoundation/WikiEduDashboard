# frozen_string_literal: true

#= Adds and removes tags to/from courses
class TagManager
  def initialize(course)
    @course = course
  end

  def manage(request)
    @request = request
    @params = request.request_parameters
    @tag_params = @params[:tag]
    @tag_params[:course_id] = @course.id
    send("handle_#{@request.request_method.downcase}")
  end

  def add(tag:, key: nil)
    create_attrs = { course_id: @course.id,
                     tag: tag,
                     key: key }
    Tag.create(create_attrs)
  end

  def initial_tags(creator:)
    tag = if Features.open_course_creation?
            # When course creation is open, the new course is already published, so the
            # user is already counted as 'returning' at this point, even if it is their
            # first course.
            creator.instructed_courses.count > 1 ? 'returning_instructor' : 'first_time_instructor'
          else
            # When courses must be approved before they are published, we can rely on
            # user#returning_instructor?.
            creator.returning_instructor? ? 'returning_instructor' : 'first_time_instructor'
          end
    create_attrs = { course_id: @course.id,
                     tag: tag,
                     key: 'course_creator' }
    Tag.create(create_attrs)
  end

  private

  def handle_post
    return if Tag.find_by(@tag_params).present?
    Tag.create(@tag_params)
  end

  def handle_delete
    return unless Tag.find_by(@tag_params).present?
    Tag.find_by(@tag_params).destroy
  end
end
