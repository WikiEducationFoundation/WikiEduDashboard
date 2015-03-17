#= Course + User join model
class CoursesUsers < ActiveRecord::Base
  belongs_to :course
  belongs_to :user

  validates :course_id, uniqueness: { scope: [:user_id, :role] }

  ####################
  # Instance methods #
  ####################
  def character_sum_ms
    update_cache unless self[:character_sum_ms]
    self[:character_sum_ms]
  end

  def character_sum_us
    update_cache unless self[:character_sum_us]
    self[:character_sum_us]
  end

  def revision_count
    update_cache unless self[:revision_count]
    self[:revision_count]
  end

  def assigned_article_title
    update_cache unless self[:assigned_article_title]
    self[:assigned_article_title]
  end

  def update_cache
    self.character_sum_ms = Revision.joins(:article)
      .where(articles: { namespace: 0 })
      .where(user_id: user.id)
      .where('characters >= 0')
      .where('date >= ?', course.start)
      .where('date <= ?', course.end)
      .sum(:characters) || 0
    self.character_sum_us = Revision.joins(:article)
      .where(articles: { namespace: 2 })
      .where(user_id: user.id)
      .where('characters >= 0')
      .where('date >= ?', course.start)
      .where('date <= ?', course.end)
      .sum(:characters) || 0
    self.revision_count = Revision.joins(:article)
      .where(user_id: user.id)
      .where('date >= ?', course.start)
      .where('date <= ?', course.end)
      .count || 0
    assignments = user.assignments.where(course_id: course.id)
    # rubocop:disable Metrics/LineLength
    self.assigned_article_title = assignments.empty? ? nil : assignments.first.article_title
    # rubocop:enable Metrics/LineLength
    save
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches
    CoursesUsers.all.each(&:update_cache)
  end
end
