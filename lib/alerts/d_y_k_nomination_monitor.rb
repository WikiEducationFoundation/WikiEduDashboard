# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/category_importer"

# This class identifies articles that have been nominated
# for the Did You Know process on English Wikipedia
class DYKNominationMonitor
  def self.create_alerts_for_course_articles
    new.create_alerts_from_page_titles
  end

  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    find_pending_dyk_nominations
    extract_page_titles_from_nominations
    normalize_titles
  end

  def create_alerts_from_page_titles
    course_articles = ArticlesCourses.joins(:article)
                                     .where(course: Course.current)
                                     .where(articles: { title: @page_titles, wiki_id: @wiki.id })
    course_articles.each do |articles_course|
      create_alert(articles_course)
    end
  end

  private

  DYK_CATEGORY = 'Category:Pending DYK nominations'
  DYK_CATEGORY_DEPTH = 0
  DYK_NAMESPACE = Article::Namespaces::TEMPLATE
  def find_pending_dyk_nominations
    @dyk_titles = CategoryImporter.new(@wiki)
                                  .page_titles_for_category(DYK_CATEGORY,
                                                            DYK_CATEGORY_DEPTH,
                                                            DYK_NAMESPACE)
  end

  def extract_page_titles_from_nominations
    @dyk_article_titles = @dyk_titles.map do |dyk_title|
      dyk_title[%r{Template:Did you know nominations/(.*)}, 1]
    end
  end

  def normalize_titles
    @page_titles = @dyk_article_titles.map do |title|
      next if title.blank?
      title.tr(' ', '_')
    end
    @page_titles.compact!
    @page_titles.uniq!
  end

  def create_alert(articles_course)
    return if alert_already_exists?(articles_course)
    alert = Alert.create!(type: 'DYKNominationAlert',
                          article_id: articles_course.article_id,
                          user_id: articles_course&.user_ids&.first,
                          course_id: articles_course.course_id)

    alert.email_instructors_and_wikipedia_experts
  end

  def alert_already_exists?(articles_course)
    Alert.exists?(article_id: articles_course.article_id,
                  course_id: articles_course.course_id,
                  type: 'DYKNominationAlert',
                  resolved: false)
  end
end
