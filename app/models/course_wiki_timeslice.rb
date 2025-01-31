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
#
class CourseWikiTimeslice < ApplicationRecord
  belongs_to :course
  belongs_to :wiki

  serialize :stats, Hash

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

  #################
  # Class methods #
  #################

  # Given a course, a wiki, and a hash of revisions like the following:
  # {:start=>"20160320", :end=>"20160401", :revisions=>[...]},
  # updates the course wiki timeslices based on the revisions.
  def self.update_course_wiki_timeslices(course, wiki, revisions)
    rev_start = revisions[:start]
    rev_end = revisions[:end]
    # Course wiki timeslices to update
    course_wiki_timeslices = CourseWikiTimeslice.for_course_and_wiki(course,
                                                                     wiki)
                                                .for_revisions_between(rev_start, rev_end)
    course_wiki_timeslices.each do |timeslice|
      # Group revisions that belong to the timeslice
      revisions_in_timeslice = revisions[:revisions].select(&:scoped_revision).select do |revision|
        timeslice.start <= revision.date && revision.date < timeslice.end
      end
      # Update cache for CourseWikiTimeslice
      timeslice.update_cache_from_revisions revisions_in_timeslice
    end
  end

  ####################
  # Instance methods #
  ####################

  # Assumes that the revisions are for their own course wiki
  def update_cache_from_revisions(revisions)
    @revisions = revisions
    @students = course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE)

    update_character_sum
    update_references_count
    update_revision_count
    update_stats
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

  def update_revision_count
    excluded_article_ids = course.articles_courses.not_tracked.pluck(:article_id)
    tracked_revisions = @revisions.reject do |revision|
      excluded_article_ids.include?(revision.article_id)
    end

    self.revision_count = tracked_revisions.count { |rev| !rev.deleted && !rev.system }
  end

  def update_stats
    return unless wiki.project == 'wikidata'
    self.stats = UpdateWikidataStatsTimeslice.new(course).build_stats_from_revisions(@revisions)
  end

  def update_needs_update
    self.needs_update = !@revisions.select(&:revision_with_error).empty?
  end
end
