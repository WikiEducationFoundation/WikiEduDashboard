# frozen_string_literal: true

#= Deletes duplicate Article records that differ by ID but match by title and namespace
class DuplicateArticleDeleter
  def initialize(wiki = nil)
    wiki ||= Wiki.default_wiki
    @wiki = wiki
  end

  ###############
  # Entry point #
  ###############
  def resolve_duplicates_for_timeslices(articles)
    grouped = articles_grouped_by_title_and_namespace(articles)
    @deleted_ids = []
    grouped.each do |article_group|
      delete_duplicates_in(article_group)
    end

    return if @deleted_ids.empty?

    articles = Article.where(id: @deleted_ids)
    # Get all courses with at least one deleted article
    course_ids = ArticlesCourses.where(article_id: @deleted_ids).pluck(:course_id).uniq
    course_ids.each do |course_id|
      # Reset articles for every course involved
      ArticlesCoursesCleanerTimeslice.reset_specific_articles(Course.find(course_id), articles)
    end
  end

  #################
  # Helper method #
  #################
  private

  def articles_grouped_by_title_and_namespace(articles)
    article_group = {}
    titles = articles.pluck(:title)
    namespace = articles.pluck(:namespace).uniq
    titles.each_slice(30000) do |title_batch|
      article_group.merge!(Article
                   .where(namespace:, wiki_id: @wiki.id, title: title_batch)
                   .group(%w[namespace wiki_id title])
                   .count)
    end
    article_group
  end

  def delete_duplicates_in(article_group)
    return unless article_group[1] > 1
    title = article_group[0][2]
    namespace = article_group[0][0]
    Rails.logger.debug { "Resolving duplicates for '#{title}, ns #{namespace}'" }
    @deleted_ids += delete_duplicates(title, namespace)
  end

  # Delete all articles with the given title
  # and namespace except for the most recently created
  def delete_duplicates(title, ns)
    articles = Article.where(title:, namespace: ns, wiki_id: @wiki.id, deleted: false)
                      .order(:created_at)
    # Default order is ascendent, so we want to keep the last article
    keeper = articles.last
    return [] if keeper.nil?

    # Here we must verify that the titles match, since searching by title is case-insensitive.
    deleted = articles.where.not(id: keeper.id).select { |article| article.title == keeper.title }
    deleted.each(&:mark_deleted!)
    deleted.map(&:id)
  end
end
