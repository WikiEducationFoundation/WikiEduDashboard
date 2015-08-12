class RevisionStat
  REVISION_TIMEFRAME = 7

  def self.get_records(date=RevisionStat::REVISION_TIMEFRAME.days.ago.to_date, course_id)
    Revision.joins(article: { articles_courses: :course })
      .where('courses.id = ?', course_id)
      .where('date >= ?', date)
      .count
  end
end
