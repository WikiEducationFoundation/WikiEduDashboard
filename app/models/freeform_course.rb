class FreeformCourse < Course
  def wiki_edits_enabled?
    false
  end

  def wiki_title
    nil
  end

  def string_prefix
    'courses_generic'
  end
end
