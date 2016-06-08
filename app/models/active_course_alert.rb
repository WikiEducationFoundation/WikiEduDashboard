# Alert for a course that has become moderately active in mainspace, intended for
# Wiki Ed's communication staff to follow up with media outlets related to the course.
# Similar to ProductiveCourseAlert, but with a different productivity threshold
class ActiveCourseAlert < Alert
  def main_subject
    course.slug
  end

  def url
    course_url
  end
end
