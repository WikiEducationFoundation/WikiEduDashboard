class CourseUtils
  generateTempId: (course) ->
    title = @slugify course.title
    school = @slugify course.school
    term = @slugify course.term
    return "#{school}/#{title}_(#{term})"

  slugify: (text) ->
    text?.split(" ").join("_")

module.exports = new CourseUtils()
