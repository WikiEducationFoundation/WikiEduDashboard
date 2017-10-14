# frozen_string_literal: true

require "#{Rails.root}/lib/importers/category_importer"

# This class identifies articles involved in deletion processes on
# English Wikipedia and creates alerts for them.
# It works by first finding all the article titles, and then matching those
# up with articles edited by students (ie, ArticlesCourses).
class ArticlesForDeletionMonitor
  def self.create_alerts_for_course_articles
    new.create_alerts_from_page_titles
  end

  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    find_deletion_discussions
    extract_page_titles_from_deletion_discussions
    find_proposed_deletions
    find_candidates_for_speedy_deletion
    normalize_titles
  end

  def create_alerts_from_page_titles
    course_articles = ArticlesCourses.joins(:article)
                                     .where(articles: { title: @page_titles, wiki_id: @wiki.id })
    course_articles.each do |articles_course|
      create_alert(articles_course)
    end
  end

  private

  def find_deletion_discussions
    category = 'Category:AfD debates'
    depth = 2
    @afd_titles = CategoryImporter.new(@wiki).page_titles_for_category(category, depth)
  end

  def find_proposed_deletions
    category = 'Category:All articles proposed for deletion'
    depth = 0
    @prod_article_titles = CategoryImporter.new(@wiki).page_titles_for_category(category, depth)
  end

  def find_candidates_for_speedy_deletion
    category = 'Category:Speedy deletion'
    # This captures the main CSD categories, but excludes more complicated things
    # that are further down the category tree.
    depth = 1
    @csd_article_titles = CategoryImporter.new(@wiki).page_titles_for_category(category, depth)
  end

  def extract_page_titles_from_deletion_discussions
    @afd_article_titles = @afd_titles.map do |afd_title|
      afd_title[%r{Wikipedia:Articles for deletion/(.*)}, 1]
    end
  end

  def normalize_titles
    all_titles = @prod_article_titles + @afd_article_titles + @csd_article_titles
    @page_titles = all_titles.map do |title|
      next if title.blank?
      title.tr(' ', '_')
    end
    @page_titles.compact!
    @page_titles.uniq!
  end

  def create_alert(articles_course)
    return if alert_already_exists?(articles_course)
    first_revision = articles_course
                     .course.revisions.where(article_id: articles_course.article_id).first
    alert = Alert.create!(type: 'ArticlesForDeletionAlert',
                          article_id: articles_course.article_id,
                          user_id: first_revision&.user_id,
                          course_id: articles_course.course_id,
                          revision_id: first_revision&.id)
    alert.email_content_expert
  end

  def alert_already_exists?(articles_course)
    Alert.exists?(article_id: articles_course.article_id,
                  course_id: articles_course.course_id,
                  type: 'ArticlesForDeletionAlert',
                  resolved: false)
  end
end
