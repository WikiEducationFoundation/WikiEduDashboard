class ClassroomProgramCourse < Course
  def wiki_edits_enabled?
    true
  end

  def wiki_title
    prefix = ENV['course_prefix'] + '/'
    escaped_slug = slug.tr(' ', '_')
    "#{prefix}#{escaped_slug}"
  end

  def string_prefix
    'courses'
  end
end
