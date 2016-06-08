# Alert for a course that is highly productive
# Similar to ActiveCourseAlert, but with a different productivity threshold
class ProductiveCourseAlert < Alert
  def main_subject
    course.slug
  end

  def url
    course_url
  end
end
