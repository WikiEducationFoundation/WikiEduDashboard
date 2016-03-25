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

  def initial_tags(creator:)
    tag = creator.returning_instructor? ? 'returning_instructor' : 'first_time_instructor'
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
