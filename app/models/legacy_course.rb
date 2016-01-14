require "#{Rails.root}/lib/course_update_manager"

# Course type for courses imported from the MediaWiki EducationProgram extension
class LegacyCourse < Course
  def wiki_edits_enabled?
    false
  end

  def wiki_title
    prefix = 'Education_Program:'
    escaped_slug = slug.tr(' ', '_')
    "#{prefix}#{escaped_slug}"
  end

  # Pulls new data from the MediaWiki ListStudents API
  def update(data={}, should_save=true)
    CourseUpdateManager.update_from_wiki(self, data, should_save)
  end
end
