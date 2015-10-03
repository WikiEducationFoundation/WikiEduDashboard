#= Queries for articles and revisions that have interesting properties
class RevisionAnalyticsService
  ################
  # Entry points #
  ################

  def self.dyk_eligible(opts={})
    new(opts).dyk_eligible
  end

  def self.suspected_plagiarism(opts={})
    new(opts).suspected_plagiarism
  end

  def self.recent_edits(opts={})
    new(opts).recent_edits
  end

  #########
  # Setup #
  #########

  def initialize(opts)
    return unless opts[:scoped] == 'true' && opts[:current_user]
    @course_ids = Course.joins(:courses_users)
                  .where('courses_users.user_id = ?', opts[:current_user].id)
                  .current.pluck(:id)
  end

  #################
  # Main routines #
  #################
  def dyk_eligible
    wp10_limit = ENV['dyk_wp10_limit'] || 30
    good_student_revisions = Revision
                             .where(user_id: student_ids)
                             .where('wp10 > ?', wp10_limit)
                             .where('date > ?', 2.months.ago)
    good_article_ids = good_student_revisions.pluck(:article_id)
    good_user_space = Article.where(id: good_article_ids)
                      .where(namespace: 2)
                      .where('title LIKE ?', '%/%') # only get subpages
                      .where('title NOT LIKE ?', '%/TWA/%') # skip TWA pages
                      .pluck(:id)
    good_draft_space = Article.where(id: good_article_ids)
                       .where(namespace: 118)
                       .pluck(:id)

    good_draft_ids = good_draft_space + good_user_space
    good_drafts = articles_sorted_by_latest_revision(good_draft_ids)
    good_drafts
  end

  def suspected_plagiarism
    if @course_ids
      suspected_revisions = Revision.where.not(ithenticate_id: nil).where(user_id: student_ids)
    else
      suspected_revisions = Revision.where.not(ithenticate_id: nil)
    end
    suspected_revisions
  end

  def recent_edits
    if @course_ids
      recent_revisions = Revision.where(user_id: student_ids).last(200)
    else
      recent_revisions = Revision.last(200)
    end
    recent_revisions
  end
  ##################
  # Helper methods #
  ##################

  def articles_sorted_by_latest_revision(article_ids)
    last_revisions = Revision
                     .where(article_id: article_ids)
                     .select('MAX(date) as date, article_id')
                     .group(:article_id)
    last_rev_dates = {}
    last_revisions.each do |revision|
      last_rev_dates[revision.article_id] = revision.date
    end

    articles = Article.where(id: article_ids).to_a
    articles.sort! { |a, b| last_rev_dates[a.id] <=> last_rev_dates[b.id] }
    articles.reverse!
  end

  # Students in current courses, excluding instructors
  def student_ids
    @course_ids ||= Course.current.pluck(:id)
    student_ids = CoursesUsers
                  .where(course_id: @course_ids, role: 0)
                  .pluck(:user_id)
    instructor_ids = CoursesUsers
                     .where(course_id: @course_ids, role: 1)
                     .pluck(:user_id)
    pure_student_ids = student_ids - instructor_ids
    pure_student_ids
  end
end
