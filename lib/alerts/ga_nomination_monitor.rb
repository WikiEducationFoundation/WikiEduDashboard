# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/category_importer"

# This class identifies articles that have been nominated
# for the Good Article process on English Wikipedia
class GANominationMonitor
  def self.create_alerts_for_course_articles
    new.create_alerts_from_page_titles
  end

  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    find_pending_ga_nominations
    extract_page_titles_from_nominations
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

  GA_CATEGORY = 'Category:Good article nominees'
  GA_CATEGORY_DEPTH = 0
  def find_pending_ga_nominations
    @ga_titles = CategoryImporter.new(@wiki)
                                 .page_titles_for_category(GA_CATEGORY, GA_CATEGORY_DEPTH)
  end

  def extract_page_titles_from_nominations
    @ga_article_titles = @ga_titles.map do |ga_title|
      ga_title[/Talk:(.*)/, 1]
    end
  end

  def normalize_titles
    @page_titles = @ga_article_titles.map do |title|
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
    alert = Alert.create!(type: 'GANominationAlert',
                          article_id: articles_course.article_id,
                          user_id: first_revision&.user_id,
                          course_id: articles_course.course_id,
                          revision_id: first_revision&.id)
    alert.email_content_expert
  end

  def alert_already_exists?(articles_course)
    Alert.exists?(article_id: articles_course.article_id,
                  course_id: articles_course.course_id,
                  type: 'GANominationAlert',
                  resolved: false)
  end
end
