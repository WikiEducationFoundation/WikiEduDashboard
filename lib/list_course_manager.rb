#= Routines for adding or removing a course to/from a cohort
class ListCourseManager
  def initialize(course, cohort, request)
    @course = course
    @already_approved = course_listed?
    @cohort = cohort
    @request = request
    @cohorts_courses_attrs = { course_id: @course.id, cohort_id: @cohort.id }
  end

  def manage
    send("handle_#{@request.request_method.downcase}")
  end

  private

  def handle_post
    return if CohortsCourses.find_by(@cohorts_courses_attrs).present?
    CohortsCourses.create(@cohorts_courses_attrs)
    send_approval_notification_emails unless @already_approved
  end

  def handle_delete
    return unless CohortsCourses.find_by(@cohorts_courses_attrs).present?
    CohortsCourses.find_by(@cohorts_courses_attrs).destroy
  end

  def course_listed?
    @course.cohorts.count > 0
  end

  def send_approval_notification_emails
    @course.instructors.each do |instructor|
      CourseApprovalMailer.send_approval_notification(@course, instructor)
    end
  end
end
