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

  # This builds i18n interface strings that vary based on state/props.
  i18n: (message_key, prefix, default_prefix = 'courses') ->
    if prefix
      message = I18n.t("#{prefix}.#{message_key}")

    if !message || message.startsWith("[missing")
      message = I18n.t("#{default_prefix}.#{message_key}")

    message

module.exports = new CourseUtils()
