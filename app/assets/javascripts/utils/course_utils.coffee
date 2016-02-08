class CourseUtils
  generateTempId: (course) ->
    title = @slugify course.title.trim()
    school = @slugify course.school.trim()
    slug = "#{school}/#{title}"
    if course.term
      term = @slugify course.term.trim()
      slug = "#{slug}_(#{term})"
    return slug

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
    I18n.t("#{prefix}.#{message_key}", {
      defaults: [{scope: "#{default_prefix}.#{message_key}"}]
    })

module.exports = new CourseUtils()
