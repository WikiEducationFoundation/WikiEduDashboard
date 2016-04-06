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

  formatArticleTitle: (article_title_input) ->
    article_title = article_title_input.trim()
    unless /http/.test(article_title)
      return article_title.replace(/_/g, ' ')

    url_parts = /\/wiki\/(.*)/.exec(article_title)
    return decodeURIComponent(url_parts[1]).replace(/_/g, ' ') if url_parts.length > 1
    return null

module.exports = new CourseUtils()
