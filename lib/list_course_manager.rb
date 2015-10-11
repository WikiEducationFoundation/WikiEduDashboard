#= Routines for adding or removing a course to/from a cohort
class ListCourseManager
  def initialize(course, cohort, request)
    @course = course
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
  end

  def handle_delete
    return unless CohortsCourses.find_by(@cohorts_courses_attrs).present?
    CohortsCourses.find_by(@cohorts_courses_attrs).destroy
  end
end
