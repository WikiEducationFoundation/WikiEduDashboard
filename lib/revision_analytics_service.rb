class RevisionAnalyticsService
  def self.dyk_eligible
    current_course_ids = Course.current.pluck(:id)
    current_student_ids = CoursesUsers
                          .where(course_id: current_course_ids, role: 0)
                          .pluck(:user_id)
    good_student_revisions = Revision
                             .where(user_id: current_student_ids)
                             .where('wp10 > ?', 50)
    good_article_ids = good_student_revisions.pluck(:article_id)
    good_user_space = Article.where(id: good_article_ids)
                             .where(namespace: 2)
                             .where('title LIKE ?', '%/%')
                             .pluck(:id)
    good_draft_space = Article.where(id: good_article_ids)
                              .where(namespace: 118)
                              .pluck(:id)

    good_drafts = Article.where(id: good_draft_space + good_user_space)
    good_drafts
  end
end
