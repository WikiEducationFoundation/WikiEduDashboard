# frozen_string_literal: true
# == Schema Information
#
# Table name: articles_courses
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  article_id    :integer
#  course_id     :integer
#  view_count    :bigint(8)        default(0)
#  character_sum :integer          default(0)
#  new_article   :boolean          default(FALSE)
#

#= ArticlesCourses is a join model between Article and Course.
#= It represents a mainspace Wikipedia article that has been worked on by a
#= student in a course.
class ArticlesCourses < ApplicationRecord
  belongs_to :article
  belongs_to :course

  scope :live, -> { joins(:article).where(articles: { deleted: false }).distinct }
  scope :new_article, -> { where(new_article: true) }
  scope :current, -> { joins(:course).merge(Course.current).distinct }
  scope :ready_for_update, -> { joins(:course).merge(Course.ready_for_update).distinct }
  scope :tracked, -> { where(tracked: true).distinct }
  scope :not_tracked, -> { where(tracked: false).distinct }

  serialize :user_ids, Array # This text field only stores user ids as text

  ####################
  # Instance methods #
  ####################
  def view_count
    update_cache unless self[:view_count]
    self[:view_count]
  end

  def character_sum
    update_cache unless self[:character_sum]
    self[:character_sum]
  end

  def references_count
    update_cache unless self[:references_count]
    self[:references_count]
  end

  def new_article
    self[:new_article]
  end

  def live_manual_revisions
    course.revisions.live.where(article_id:)
  end

  def all_revisions
    course.all_revisions.where(article_id:)
  end

  def article_revisions
    article.revisions.where('date >= ?', course.start).where('date <= ?', course.end)
  end

  # rubocop:disable Metrics/AbcSize
  def update_cache
    revisions = live_manual_revisions.load

    self.character_sum = revisions.sum { |r| r.characters.to_i.positive? ? r.characters : 0 }
    self.references_count = revisions.sum(&:references_added)
    self.earliest_edit = earliest_revision(revisions)
    self.average_pageviews = average_views_since_earliest_revision
    self.view_count = views_since_earliest_revision
    self.user_ids = associated_user_ids(revisions)

    # We use the 'all_revisions' scope so that the dashboard system edits that
    # create sandboxes are not excluded, since those are often wind up being the
    # first edit of a mainspace article's revision history
    self.new_article = new_article || # If it's already known to be new, that won't change
                       all_revisions.exists?(new_article: true) || # First edit was by a student
                       # First edit was done automatically by the Dashboard during the course
                       article_revisions.exists?(new_article: true, system: true)
    save
  end
  # rubocop: enable Metrics/AbcSize

  def earliest_revision(revisions)
    return earliest_edit if earliest_edit?
    return if revisions.blank?
    revisions.min_by(&:date).date
  end

  def average_views_since_earliest_revision
    return unless earliest_edit
    last_updated = views_updated_at ? views_updated_at.to_date : nil
    current_date = Time.now.utc.to_date
    # Update the average if it hasn't been updated yet
    # If yes, then update only if it has been over 7 days
    return average_pageviews if last_updated && (current_date - last_updated) < 7

    # In order to optimize the computation of average, we do a small trick.
    # We don't fetch the pageviews data since earliest_edit. As we already have the average
    # value till last_updated date, we get the total count by multiplying it with the number
    # of days. Hence, we fetch the pageviews data only for last 7 days and then calculate
    # the new average value by dividing total count by total number of days since earliest edit.

    last_week_average = WikiPageviews.new(article).average_views(last_updated, current_date)
    # Total sum of pageviews from earliest edit till last updated
    views_count_1 = average_pageviews * (last_updated - earliest_edit.to_date)
    # Total sum of pageviews from last_updated till current_date
    views_count_2 = last_week_average * (current_date - last_updated)
    new_average = (views_count_1 + views_count_2) / (current_date - earliest_edit.to_date)

    # Check if newly calculated average satisfies the criteria for spike in pageviews
    check_pageviews_spike(new_average, average_pageviews, last_updated, current_date)
    self.views_updated_at = Time.now.utc
    new_average
  end

  def views_since_earliest_revision
    return unless earliest_edit
    days = (Time.now.utc.to_date - earliest_edit.to_date).to_i
    days * average_pageviews
  end

  def associated_user_ids(revisions)
    return [] if revisions.blank?
    revisions.filter_map(&:user_id).uniq
  end

  def check_pageviews_spike(new_average, old_average, start_date, end_date)
    return unless old_average
    return unless new_average >= old_average * 5 # 5-fold spike
    daily_view_data = WikiPageviews.new(article).views_for_article({ start_date:, end_date: })

    # Alert if there have been atleast 100 views since checked last time.
    daily_view_data.each do |_key, value|
      if (value - old_average) > 100
        PageviewSpikeMailer.send_spike_alert_email(article_course)
        break
      end
    end
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches(articles_courses)
    articles_courses.find_each(&:update_cache)
  end

  def self.update_from_course(course)
    course_article_ids = course.articles.where(wiki: course.wikis).pluck(:id)
    revision_article_ids = article_ids_by_namespaces(course)

    # Remove all the ArticlesCourses that do not correspond to course revisions.
    # That may happen if the course dates changed, so some revisions are no
    # longer part of the course.
    # Also remove records for articles that aren't on a tracked wiki.
    valid_article_ids = revision_article_ids & course_article_ids
    destroy_invalid_records(course, valid_article_ids)

    # Add new ArticlesCourses
    # Using `insert_all` is massively more efficient than inserting them one at a time.
    article_ids_without_ac = revision_article_ids - course_article_ids
    tracked_wiki_ids = course.wikis.pluck(:id)
    new_article_ids = Article.where(id: article_ids_without_ac, wiki_id: tracked_wiki_ids)
                             .pluck(:id)
    new_records = new_article_ids.map do |id|
      { article_id: id, course_id: course.id }
    end

    return if new_records.empty?
    # Do this is batches to avoid running the MySQL server out of memory
    new_records.each_slice(5000) do |new_record_slice|
      # rubocop:disable Rails/SkipsModelValidations
      insert_all new_record_slice
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def self.destroy_invalid_records(course, valid_article_ids)
    course_ac_records = course.articles_courses.pluck(:id, :article_id)
    course_ac_records.each do |(id, article_id)|
      next if valid_article_ids.include?(article_id)
      find(id).destroy
    end
  end

  def self.article_ids_by_namespaces(course)
    # Return article ids from revisions corresponding to tracked wikis and namespaces
    article_ids = []
    course.tracked_namespaces.map do |wiki_ns|
      wiki = wiki_ns[:wiki]
      namespace = wiki_ns[:namespace]
      article_ids << course.revisions.joins(:article).where(articles: { wiki:, namespace: })
                           .distinct.pluck(:article_id)
    end
    return article_ids.flatten
  end
end
