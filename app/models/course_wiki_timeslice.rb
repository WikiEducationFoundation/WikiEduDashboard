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
#
class CourseWikiTimeslice < ApplicationRecord
  belongs_to :course
  belongs_to :wiki

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

    self.revision_count += tracked_revisions.count { |rev| !rev.deleted }
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
