# frozen_string_literal: true

# == Schema Information
#
# Table name: course_user_wiki_timeslices
#
#  id                  :bigint           not null, primary key
#  course_user_id      :integer          not null
#  wiki_id             :integer          not null
#  start               :datetime
#  end                 :datetime
#  last_mw_rev_id      :integer
#  total_uploads       :integer          default(0)
#  character_sum_ms    :integer          default(0)
#  character_sum_us    :integer          default(0)
#  character_sum_draft :integer          default(0)
#  references_count    :integer          default(0)
#  revision_count      :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class CourseUserWikiTimeslice < ApplicationRecord
  belongs_to :courses_users, foreign_key: 'course_user_id'
  belongs_to :wiki

  ####################
  # Instance methods #
  ####################

  # Assumes that the revisions are for their own course user wiki
  def update_cache_from_revisions(revisions)
    @revisions = revisions
    @liverevisions = live_revisions
    tracked_namespace_revisions = live_revisions_in_tracked_namespaces
    self.total_uploads = courses_users.course.uploads.where(user_id: courses_users.user_id).count
    update_character_sum(@liverevisions, tracked_namespace_revisions)
    self.references_count += references_sum(tracked_namespace_revisions)

    self.revision_count += filtered_live_revisions.size || 0
    save
  end

  private

  # Returns tracked revisions (revisions for tracked article courses)
  # for which already exists an article record
  # made for user_id. Notice that revisions are already made for a given user_id
  def live_revisions
    excluded_article_ids = courses_users.course.articles_courses.not_tracked.pluck(:article_id)
    tracked_revisions = @revisions.reject do |revision|
      excluded_article_ids.include?(revision.article_id)
    end
    # Ensure that article record exists for article_ids
    article_ids = tracked_revisions.map(&:article_id)
    articles_ids_with_article_records = Article.where(id: article_ids).pluck(:id)
    filtered_tracked_revisions = tracked_revisions.select do |revision|
      articles_ids_with_article_records.include?(revision.article_id)
    end
    filtered_tracked_revisions.reject(&:deleted)
  end

  def live_revisions_in_tracked_namespaces
    course_article_ids = courses_users.course.articles.pluck(:id)
    live_revisions.select do |revision|
      course_article_ids.include?(revision.article_id)
    end
  end

  def filtered_live_revisions
    article_ids = @liverevisions.map(&:article_id)
    articles = Article.where(id: article_ids, deleted: false)

    # Filter revisions based on the fetched articles
    live_article_ids = articles.pluck(:id)
    @liverevisions.select do |rev|
      live_article_ids.include?(rev.article_id)
    end
  end

  def update_character_sum(revisions, tracked_namespace_revisions)
    self.character_sum_ms += character_sum(tracked_namespace_revisions,
                                           Article::Namespaces::MAINSPACE)
    self.character_sum_us += character_sum(revisions, Article::Namespaces::USER)
    self.character_sum_draft += character_sum(revisions, Article::Namespaces::DRAFT)
  end

  ##################
  # Helper methods #
  ##################

  def character_sum(revisions, namespace)
    article_ids = revisions.map(&:article_id)
    articles = Article.where(id: article_ids, namespace:, deleted: false)

    # Filter revisions based on the fetched articles
    article_ids_in_namespace = articles.pluck(:id)
    filtered_revisions = revisions.select do |rev|
      article_ids_in_namespace.include?(rev.article_id) && rev.characters >= 0
    end

    # Sum characters
    filtered_revisions.sum(&:characters)
  end

  def references_sum(revisions)
    article_ids = revisions.map(&:article_id)
    articles = Article.where(id: article_ids, namespace: Article::Namespaces::MAINSPACE,
                             deleted: false)

    # Filter revisions based on the fetched articles
    article_ids_in_mainspace = articles.pluck(:id)
    filtered_revisions = revisions.select do |rev|
      article_ids_in_mainspace.include?(rev.article_id)
    end
    filtered_revisions.sum(&:references_added)
  end
end
