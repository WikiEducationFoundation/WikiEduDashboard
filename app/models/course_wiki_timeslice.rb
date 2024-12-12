# frozen_string_literal: true

# == Schema Information
#
# Table name: course_wiki_timeslices
#
#  id                   :bigint           not null, primary key
#  start                :datetime
#  end                  :datetime
#  last_mw_rev_id       :integer
#  character_sum        :integer          default(0)
#  references_count     :integer          default(0)
#  revision_count       :integer          default(0)
#  upload_count         :integer          default(0)
#  uploads_in_use_count :integer          default(0)
#  upload_usages_count  :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  course_id            :integer          not null
#  wiki_id              :integer          not null
#  last_mw_rev_datetime :datetime
#  needs_update         :boolean          default(FALSE)
#  stats                :text(65535)
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
      revisions_in_timeslice = revisions[:revisions].select do |revision|
        timeslice.start <= revision.date && revision.date < timeslice.end
      end
      # Update cache for CourseWikiTimeslice
      timeslice.update_cache_from_revisions revisions_in_timeslice
    end
  end

  # These three class methods are used to create missing timeslices when there is no
  # guarantee that all courses wikis are in the same state.
  def self.max_min_course_start(course)
    course.wikis.filter_map do |wiki|
      CourseWikiTimeslice.for_course_and_wiki(course, wiki).minimum(:start)
    end.max
  end

  def self.min_max_course_start(course)
    course.wikis.filter_map do |wiki|
      CourseWikiTimeslice.for_course_and_wiki(course, wiki).maximum(:start)
    end.min
  end

  def self.min_max_course_end(course)
    course.wikis.filter_map do |wiki|
      CourseWikiTimeslice.for_course_and_wiki(course, wiki).maximum(:end)
    end.min
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
    update_upload_count
    update_uploads_in_use_count
    update_upload_usages_count
    self.needs_update = false
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

  def update_upload_count
    # TODO: count only uploads updated at during the timeslice range
    self.upload_count = course.uploads.count
  end

  def update_uploads_in_use_count
    # TODO: count only uploads updated at during the timeslice range
    self.uploads_in_use_count = course.uploads_in_use.count
  end

  def update_upload_usages_count
    # TODO: count only uploads updated at during the timeslice range
    self.upload_usages_count = course.uploads_in_use.sum(:usage_count)
  end
end
