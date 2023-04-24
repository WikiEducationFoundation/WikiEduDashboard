# frozen_string_literal: true

class ArticleChangeNamespaceAlertManager
    def self.create_alerts_for_article_namespace_change
      new.create_alerts_for_article_namespace_change
    end

    def initialize
      @articles = Article.all
      @article_courses = ArticlesCourses.includes(:course).where(article_id: @articles.pluck(:id)).distinct
    end
  
    def create_alerts_for_article_namespace_change
      @article_courses.each do |article|
        next unless namespace_changed?(article)
        next if Alert.exists?(article_id: article.id, type: 'ArticleNamespaceChangeAlert')
        alert = Alert.create(type: 'ArticleNamespaceChangeAlert',
                             article_id: article.id)
        alert.email_content_expert
      end
    end

    private 

    def namespace_changed?(article)
      course.articles_courses.each do |ac|
        next unless ac.article.namespace != 0
        return true
      end
      false
    end
  end
