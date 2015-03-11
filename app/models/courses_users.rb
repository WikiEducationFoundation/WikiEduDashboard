#= Course + User join model
class CoursesUsers < ActiveRecord::Base
  belongs_to :course
  belongs_to :user

  ####################
  # Instance methods #
  ####################
  def character_sum_ms
    update_cache unless read_attribute(:character_sum_ms)
    read_attribute(:character_sum_ms)
  end

  def character_sum_us
    update_cache unless read_attribute(:character_sum_us)
    read_attribute(:character_sum_us)
  end

  def revision_count
    update_cache unless read_attribute(:revision_count)
    read_attribute(:revision_count)
  end

  def assigned_article_title
    update_cache unless read_attribute(:assigned_article_title)
    read_attribute(:assigned_article_title)
  end

  def update_cache
    self.character_sum_ms = Revision.joins(:article)
      .where(articles: { namespace: 0 })
      .where(user_id: user.id)
      .where('characters >= 0')
      .where('date >= ?', course.start)
      .sum(:characters) || 0
    self.character_sum_us = Revision.joins(:article)
      .where(articles: { namespace: 2 })
      .where(user_id: user.id)
      .where('characters >= 0')
      .where('date >= ?', course.start)
      .sum(:characters) || 0
    self.revision_count = Revision.joins(:article)
      .where(user_id: user.id)
      .where('date >= ?', course.start)
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
