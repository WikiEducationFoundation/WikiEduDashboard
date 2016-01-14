class VisitingScholarship < Course
  has_many(:revisions, lambda do |course|
    where('date >= ?', course.start)
    .where('date <= ?', course.end)
    .where(article_id: course.assignments.pluck(:article_id))
  end, through: :students)

  def wiki_edits_enabled?
    false
  end
end
