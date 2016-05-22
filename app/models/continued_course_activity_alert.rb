# Alert for a course that has been editing in mainspace after the end date
class ContinuedCourseActivityAlert < Alert
  def main_subject
    course.slug
  end

  def url
    course_url
  end
end
