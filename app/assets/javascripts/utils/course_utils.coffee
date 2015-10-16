class CourseUtils
  generateTempId: (course) ->
    title = @slugify course.title.trim()
    school = @slugify course.school.trim()
    term = @slugify course.term.trim()
    return "#{school}/#{title}_(#{term})"

  slugify: (text) ->
    text?.split(" ").join("_")

  cleanupCourseSlugComponents: (course) ->
    cleanedCourse = course
    cleanedCourse.title = course.title.trim()
    cleanedCourse.school = course.school.trim()
    cleanedCourse.term = course.term.trim()
    return cleanedCourse

module.exports = new CourseUtils()
