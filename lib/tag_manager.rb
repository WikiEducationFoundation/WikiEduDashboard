#= Adds and removes tags to/from courses
class TagManager
  # tested via courses_controller

  def initialize(course, request)
    @course = course
    @request = request
    @params = request.request_parameters
    @tag_params = @params[:tag]
  end

  def manage
    send("handle_#{@request.request_method.downcase}")
  end

  private

  def handle_post
    return if Tag.find_by(@tag_params).present?
    create_attrs = { course_id: @course.id }.merge(@tag_params)
    Tag.create(create_attrs)
  end

  def handle_delete
    return unless Tag.find_by(@tag_params).present?
    Tag.find_by(@tag_params).destroy
  end
end
