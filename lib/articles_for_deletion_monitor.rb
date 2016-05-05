require "#{Rails.root}/lib/importers/category_importer"

class ArticlesForDeletionMonitor
  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    find_deletion_discussions
    find_page_titles
  end

  def create_alerts_for_new_articles
    course_articles = ArticlesCourses.new_article
                                     .joins(:article)
                                     .where(articles: { title: @page_titles })
    course_articles.each do |articles_course|
      create_alert(articles_course)
    end
  end

  private

  def find_deletion_discussions
    category = 'Category:AfD debates'
    depth = 2
    @afd_titles ||= CategoryImporter.new(@wiki).page_titles_for_category(category, depth)
  end

  def find_page_titles
    titles = @afd_titles.map do |afd_title|
      title = afd_title[%r{Wikipedia:Articles for deletion/(.*)}, 1]
      next if title.blank?
      title.tr(' ', '_')
    end
    @page_titles = titles.compact!
  end

  def create_alert(articles_course)
    return if alert_already_exists?(articles_course)
    first_revision = articles_course.article.revisions.find_by(new_article: true)
    alert = Alert.create!(
      type: 'ArticlesForDeletionAlert',
      article_id: articles_course.article_id,
      user_id: first_revision.try(:user_id),
      course_id: articles_course.course_id,
      revision_id: first_revision.try(:id)
    )
    alert.email_content_expert
  end

  def alert_already_exists?(articles_course)
    Alert.exists?(article_id: articles_course.article_id,
                  course_id: articles_course.course_id,
                  type: 'ArticlesForDeletionAlert')
  end
end
