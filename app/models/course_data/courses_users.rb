# frozen_string_literal: true
# == Schema Information
#
# Table name: courses_users
#
#  id                     :integer          not null, primary key
#  created_at             :datetime
#  updated_at             :datetime
#  course_id              :integer
#  user_id                :integer
#  character_sum_ms       :integer          default(0)
#  character_sum_us       :integer          default(0)
#  revision_count         :integer          default(0)
#  assigned_article_title :string(255)
#  role                   :integer          default(0)
#  recent_revisions       :integer          default(0)
#  character_sum_draft    :integer          default(0)
#  real_name              :string(255)
#  role_description       :string(255)
#  total_uploads          :integer
#  references_count       :integer          default(0)
#

require_dependency "#{Rails.root}/lib/course_cleanup_manager"

#= Course + User join model
class CoursesUsers < ApplicationRecord
  belongs_to :course
  belongs_to :user
  before_destroy :cleanup

  has_many :assignments, ->(ac) { where(course_id: ac.course_id) },
           through: :user

  has_many :survey_notifications

  has_many :course_user_wiki_timeslices, lambda { |courses_users|
                                           where user: courses_users.user
                                         }, through: :course

  validates :course_id, uniqueness: { scope: %i[user_id role] }

  scope :current, -> { joins(:course).merge(Course.current).distinct }
  scope :ready_for_update, lambda {
                             joins(:course).where(course: Course.ready_for_update).distinct
                           }
  scope :with_instructor_role, -> { where(role: Roles::INSTRUCTOR_ROLE) }
  scope :with_student_role, -> { where(role: Roles::STUDENT_ROLE) }

  ####################
  # CONSTANTS        #
  ####################

  module Roles
    VISITOR_ROLE          = -1
    STUDENT_ROLE          = 0
    INSTRUCTOR_ROLE       = 1
    CAMPUS_VOLUNTEER_ROLE = 2
    ONLINE_VOLUNTEER_ROLE = 3
    WIKI_ED_STAFF_ROLE    = 4
  end

  ROLE_NAMES = {
    Roles::STUDENT_ROLE => 'Editor',
    Roles::INSTRUCTOR_ROLE => 'Facilitator',
    Roles::CAMPUS_VOLUNTEER_ROLE => 'Campus Volunteer',
    Roles::ONLINE_VOLUNTEER_ROLE => 'Online Volunteer',
    Roles::WIKI_ED_STAFF_ROLE => 'Wiki Education Staff'
  }.freeze

  ####################
  # Instance methods #
  ####################

  def contribution_url
    "#{course.home_wiki.base_url}/wiki/Special:Contributions/#{user.url_encoded_username}"
  end

  # Provides a link to the list of all of a user's subpages, ie, sandboxes.
  def sandbox_url
    "#{course.home_wiki.base_url}/wiki/Special:PrefixIndex/User:#{user.url_encoded_username}"
  end

  def talk_page_url
    "#{course.home_wiki.base_url}/wiki/User_talk:#{user.url_encoded_username}"
  end

  def assigned_article_title
    update_cache unless self[:assigned_article_title]
    self[:assigned_article_title]
  end

  def content_expert
    role.positive? && user.permissions == 1 && user.greeter == true
  end

  def program_manager
    role.positive? && user.permissions == 1 && user.greeter == false
  end

  def live_revisions_in_tracked_namespaces
    course_article_ids = course.articles.pluck(:id)
    live_revisions.where(article_id: course_article_ids)
  end

  def live_revisions
    course.tracked_revisions.joins(:article).where(user_id:).live
  end

  def update_character_sum(revisions, tracked_namespace_revisions)
    self.character_sum_ms = character_sum(tracked_namespace_revisions,
                                          Article::Namespaces::MAINSPACE)
    self.character_sum_us = character_sum(revisions, Article::Namespaces::USER)
    self.character_sum_draft = character_sum(revisions, Article::Namespaces::DRAFT)
  end

  def update_values_from_timeslices
    self.character_sum_ms = course_user_wiki_timeslices.sum(&:character_sum_ms)
    self.character_sum_us = course_user_wiki_timeslices.sum(&:character_sum_us)
    self.character_sum_draft = course_user_wiki_timeslices.sum(&:character_sum_draft)
    self.references_count = course_user_wiki_timeslices.sum(&:references_count)
    self.revision_count = course_user_wiki_timeslices.sum(&:revision_count)
  end

  # rubocop:disable Metrics/AbcSize
  def update_cache
    revisions = live_revisions
    tracked_namespace_revisions = live_revisions_in_tracked_namespaces
    self.total_uploads = course.uploads.where(user_id:).count
    update_character_sum(revisions, tracked_namespace_revisions)
    self.references_count = references_sum(tracked_namespace_revisions)
    self.revision_count = revisions.where(articles: { deleted: false }).size || 0
    self.recent_revisions = RevisionStat.recent_revisions_for_courses_user(self).count
    assignments = user.assignments.where(course_id:)
    self.assigned_article_title = assignments.empty? ? '' : assignments.first.article_title
    save
  end
  # rubocop: enable Metrics/AbcSize

  def update_cache_from_timeslices
    # total_uploads is not implemented yet as a timeslice attribute
    self.total_uploads = course.uploads.where(user_id:).count

    update_values_from_timeslices

    # recent_revisions field doesn't belong to timeslices
    self.recent_revisions = RevisionStatTimeslice.new(course)
                                                 .recent_revisions_for_courses_user(self)
    # assigned_article_title field doesn't belong to timeslices
    assignments = user.assignments.where(course_id:)
    self.assigned_article_title = assignments.empty? ? '' : assignments.first.article_title
    save
  end

  ##################
  # Helper methods #
  ##################
  def character_sum(revisions, namespace)
    revisions
      .where(articles: { namespace:, deleted: false })
      .where('characters >= 0')
      .sum(:characters) || 0
  end

  def references_sum(revisions)
    revisions
      .where(articles: { namespace: Article::Namespaces::MAINSPACE, deleted: false })
      .sum(&:references_added)
  end

  def cleanup
    Assignment.where(user_id:, course_id:).destroy_all
    survey_notifications.destroy_all
    CourseCleanupManager.new(course, user).cleanup_articles
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches(courses_users)
    courses_users.includes(:user).find_each(&:update_cache)
  end

  def self.update_all_caches_from_timeslices(courses_users)
    courses_users.includes(:user).find_each(&:update_cache_from_timeslices)
  end
end
