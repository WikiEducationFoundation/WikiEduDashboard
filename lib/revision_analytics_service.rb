class RevisionAnalyticsService
  def self.dyk_eligible
    Article
      .joins(:revisions)
      .joins(courses: { courses_users: :user })
      .references(:all)
      .merge(Course.current)
      .where{ revisions.wp10 > 50 }
      .where{(namespace == 118) | ((namespace == 2) & (title =~ '%/%'))}
  end
end
