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
    set_article_ids
  end

  def create_alerts_from_page_titles
    course_articles = ArticlesCourses.where(article_id: @article_ids)
    course_articles.each do |articles_course|
      create_alert(articles_course)
    end
  end

  private

  GA_CATEGORY = 'Category:Good article nominees'
  GA_CATEGORY_DEPTH = 0
  def find_pending_ga_nominations
    # These are all talk pages, so the default namespaces for CategoryImporter are fine.
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

  def set_article_ids
    # Use only relevant namespaces:
    # - MAINSPACE: actual articles being nominated
    # - TALK: source of GA nominations (e.g., Talk:Some_Article)
    # Matches CategoryImporter scope and supports index-efficient queries.
    namespace = [Article::Namespaces::MAINSPACE, Article::Namespaces::TALK]
    @article_ids = Article.where(namespace:, wiki_id: @wiki.id, title: @page_titles).pluck(:id)
  end

  def create_alert(articles_course)
    return if alert_already_exists?(articles_course)
    alert = Alert.create!(type: 'GANominationAlert',
                          article_id: articles_course.article_id,
                          user_id: articles_course&.user_ids&.first,
                          course_id: articles_course.course_id)
    alert.email_content_expert
  end

  def alert_already_exists?(articles_course)
    Alert.exists?(article_id: articles_course.article_id,
                  course_id: articles_course.course_id,
                  type: 'GANominationAlert',
                  resolved: false)
  end
end
