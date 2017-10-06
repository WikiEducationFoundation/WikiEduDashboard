# frozen_string_literal: true

#= Provides a count of recent revisions by a user(s)
class RevisionStat
  REVISION_TIMEFRAME = 7

  def self.get_records(date: RevisionStat::REVISION_TIMEFRAME.days.ago.to_date,
                       course_id:)
    Revision.joins(article: { articles_courses: :course })
            .where('courses.id = ?', course_id)
            .where('date >= ?', date)
            .count
  end

  def self.recent_revisions_for_courses_user(courses_user)
    Revision.where(user_id: courses_user.user_id)
            .where('date >= ?', REVISION_TIMEFRAME.days.ago.to_date)
  end
end
