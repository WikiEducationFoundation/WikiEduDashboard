class RevisionAnalyticsService

  def self.dyk_eligible
    current_course_ids = Course.current.pluck(:id)
    current_student_ids = CoursesUsers
                          .where(course_id: current_course_ids, role: 0)
                          .pluck(:user_id)
    Article
      .eager_load(:revisions)
      .where { revisions.wp10 > 30 }
      .where(revisions: { user_id: current_student_ids })
      .where { (namespace == 118) | ((namespace == 2) & ('title like %/%')) }
  end
end
