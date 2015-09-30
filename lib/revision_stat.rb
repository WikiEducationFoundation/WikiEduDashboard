#= Provides a count of recent revisions by a user(s)
class RevisionStat
  REVISION_TIMEFRAME = 7

  def self.get_records(date=RevisionStat::REVISION_TIMEFRAME.days.ago.to_date,
                       course_id)
    Revision.joins(article: { articles_courses: :course })
      .where('courses.id = ?', course_id)
      .where('date >= ?', date)
      .count
  end

  def self.recent_revisions_for_user_and_course(user, course)
    cu = CoursesUsers.find_by(user_id: user.id, course_id: course.id)
    return [] unless cu.present?
    rev_user = cu.user
    Revision.where(user_id: rev_user.id)
      .where('date >= ?', REVISION_TIMEFRAME.days.ago.to_date)
  end
end
