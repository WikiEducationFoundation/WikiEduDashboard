# frozen_string_literal: true

class ArticleChangeNamespaceAlertManager
  # rubocop:disable Lint/UnusedMethodArgument
  def self.create_alerts_for_article_namespace_change(article)
    new.create_alerts_for_article_namespace_change
  end
  # rubocop:enable Lint/UnusedMethodArgument

  def initialize
    @articles = Article.all
    @article_courses = ArticlesCourses.includes(:course)
                                      .where(article_id: @articles.pluck(:id)).distinct
  end

  def create_alerts_for_article_namespace_change
    @article_courses.each do |article|
      next if Alert.exists?(article_id: article.id, type: 'ArticleNamespaceChangeAlert')
      alert = Alert.create(type: 'ArticleNamespaceChangeAlert',
                           article_id: article.id,
                           message: "#{article.title}" 'moved out out of' "#{article.namespace}")
      alert.email_content_expert
    end
  end
end
