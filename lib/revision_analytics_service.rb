class RevisionAnalyticsService

  def self.dyk_eligible
    Article
      .eager_load(:revisions)
      .eager_load(:courses)
      .references(:all)
      .where{ revisions.wp10 > 5 }
      .where{(namespace == 118) | ((namespace == 2) & (title !~ '%/%'))}
  end

end
