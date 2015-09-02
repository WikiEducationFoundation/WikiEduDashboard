class RevisionAnalyticsService
  def self.dyk_eligible
    wm10_limit = ENV['dyk_wp10_limit'] || 30
    Article
      .joins(:revisions)
      .joins(courses: { courses_users: :user })
      .references(:all)
      .merge(Course.current)
      .where { revisions.wp10 > wm10_limit }
      .where { (namespace == 118) | ((namespace == 2) & (title =~ '%/%')) }
  end
end
