class VisitingScholarship < Course
  has_many(:revisions, lambda do |course|
    where('date >= ?', course.start)
    .where('date <= ?', course.end)
    .where(article_id: course.assignments.pluck(:article_id))
  end, through: :students)

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
