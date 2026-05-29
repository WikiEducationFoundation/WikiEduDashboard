# frozen_string_literal: true

# == Schema Information
#
# Table name: course_wiki_timeslices
#
#  id                   :bigint           not null, primary key
#  course_id            :integer          not null
#  wiki_id              :integer          not null
#  start                :datetime
#  end                  :datetime
#  character_sum        :integer          default(0)
#  references_count     :integer          default(0)
#  revision_count       :integer          default(0)
#  stats                :text(65535)
#  last_mw_rev_datetime :datetime
#  needs_update         :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  mw_rev_count         :integer          default(0)
#  needs_reaggregation  :boolean          default(FALSE)
#
class CourseWikiTimeslice < ApplicationRecord
  belongs_to :course
  belongs_to :wiki

  serialize :stats, type: Hash

  scope :for_course_and_wiki, ->(course, wiki) { where(course:, wiki:) }
  # Returns the timeslice to which a datetime belongs (it should be a single timeslice)
  scope :for_datetime, ->(datetime) { where('start <= ? AND end > ?', datetime, datetime) }
  # Returns all the timeslices in a given period
  scope :in_period, lambda { |period_start, period_end|
                      where('start >= ? AND end <= ?', period_start, period_end)
                    }
  scope :for_revisions_between, lambda { |period_start, period_end|
    in_period(period_start, period_end).or(for_datetime(period_start)).or(for_datetime(period_end))
  }
  scope :needs_update, -> { where(needs_update: true) }
  scope :needs_reaggregation, -> { where(needs_reaggregation: true) }

  #################
  # Class methods #
  #################

  # Given a course, a wiki, and a hash of revisions like the following:
  # {:start=>"20160320000000", :end=>"20160320235959", :revisions=>[...]},
  # where start and end span a single timeslice period (end is 1 second
  # before the next timeslice boundary), updates the course wiki timeslice.
  def self.update_course_wiki_timeslices(course, wiki, revisions)
    timeslices = for_course_and_wiki(course, wiki)
                 .for_revisions_between(revisions[:start], revisions[:end])
    if timeslices.size > 1
      Sentry.capture_message "Multiple timeslices matched for course #{course.slug}",
                             level: 'error',
                             extra: { course_id: course.id, wiki_id: wiki.id,
                                      start: revisions[:start], end: revisions[:end] }
    end
    timeslices.first.update_cache_from_revisions revisions[:revisions]
  end

  def self.update_from_acuwt(course, wiki, start, finish, revisions = nil)
    find_by!(course:, wiki:, start:, end: finish).update_cache_from_acuwt(revisions)
  end

  ####################
  # Instance methods #
  ####################

  # Updates CWT stats from existing ACUWT rows without fetching from MediaWiki.
  # TODO: Remove the revisions parameter once CWT stats depend fully on ACUWT.
  # Until then, mw_rev_count and needs_update are transitionally still derived
  # from MediaWiki-fetched revisions. Pass nil during pure reaggregation (no fetch).
  def update_cache_from_acuwt(revisions = nil)
    @students = course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE)
    update_character_sum_from_acuwt
    update_references_count_from_acuwt
    update_revision_count_from_acuwt
    update_stats_from_acuwt
    if revisions
      @revisions = revisions.select(&:scoped)
      update_mw_rev_count
      update_needs_update
    end
    self.needs_reaggregation = false
    save
  end

  # Assumes that the revisions are for their own course wiki
  def update_cache_from_revisions(revisions)
    # Only work with scoped revisions
    @revisions = revisions.select(&:scoped)
    @students = course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE)
    update_character_sum
    update_references_count
    update_revision_count
    update_stats
    update_mw_rev_count
    update_needs_update
    save
  end

  private

  ##################
  # Cache updaters #
  ##################

  def update_character_sum
    # Count character sum in tracked spaces from course user wiki timeslices
    character_sum = 0
    @students.each do |student|
      character_sum += student.course_user_wiki_timeslices.where(wiki:,
                                                                 start:).sum(:character_sum_ms)
    end
    self.character_sum = character_sum
  end

  def update_references_count
    # Count character sum in tracked spaces from course user wiki timeslices
    references_count = 0
    @students.each do |student|
      references_count += student
                          .course_user_wiki_timeslices
                          .where(wiki:, start:)
                          .sum(:references_count)
    end
    self.references_count = references_count
  end

  def update_character_sum_from_acuwt
    self.character_sum = acuwt_mainspace_tracked_student_records.sum(:character_sum)
  end

  def update_references_count_from_acuwt
    self.references_count = acuwt_mainspace_tracked_student_records.sum(:references_count)
  end

  def update_revision_count_from_acuwt
    query = ArticleCourseUserWikiTimeslice
              .where(course:, wiki:, start:)
              .where.not(article_id: not_tracked_article_ids)
    query = query.where(article_id: course.scoped_article_ids) if
      course.only_scoped_articles_course?
    self.revision_count = query.sum(:revision_count)
  end

  def acuwt_mainspace_tracked_student_records
    @acuwt_mainspace_tracked_student_records ||= begin
      student_user_ids = @students.pluck(:user_id)
      query = ArticleCourseUserWikiTimeslice
                .joins(:article)
                .where(course:, wiki:, start:, user_id: student_user_ids)
                .where.not(article_id: not_tracked_article_ids)
                .where(articles: { namespace: Article::Namespaces::MAINSPACE, deleted: false })
      query = query.where(article_id: course.scoped_article_ids) if
        course.only_scoped_articles_course?
      query
    end
  end

  def not_tracked_article_ids
    @not_tracked_article_ids ||= course.articles_courses.not_tracked.pluck(:article_id)
  end

  def update_revision_count
    tracked_revisions = @revisions.reject do |revision|
      not_tracked_article_ids.include?(revision.article_id)
    end

    self.revision_count = tracked_revisions.count { |rev| !rev.deleted && !rev.system }
  end

  # Must mirror the same filter that CourseRevisionUpdater#new_revisions? applies
  # to the live fetched revisions, so the two counts are comparable.
  # Exclude non-scoped (pre-filtered in @revisions) and system edits.
  def update_mw_rev_count
    self.mw_rev_count = @revisions.count { |rev| !rev.system }
  end

  def update_stats
    return unless wiki.project == 'wikidata'
    self.stats = UpdateWikidataStatsTimeslice.new(course).build_stats_from_revisions(@revisions)
  end

  def update_stats_from_acuwt
    return unless wiki.project == 'wikidata'
    query = ArticleCourseUserWikiTimeslice.where(course:, wiki:, start:)
    query = query.where(article_id: course.scoped_article_ids) if
      course.only_scoped_articles_course?
    individual_stats = query.map(&:stats).compact
    self.stats = UpdateWikidataStatsTimeslice.new(course).sum_up_stats(individual_stats)
  end

  def update_needs_update
    self.needs_update = @revisions.any?(&:error)
  end
end
