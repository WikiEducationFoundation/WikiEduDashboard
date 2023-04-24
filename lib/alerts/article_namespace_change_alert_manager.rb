# frozen_string_literal: true

class ArticleChangeNamespaceAlertManager
    def self.create_alerts_for_article_namespace_change
      new.create_alerts_for_article_namespace_change
    end
  
    def initialize
      @articles = ArticlesCourses.article_ids_by_namespaces(['main', 'user', 'draft'])
    end
  
    def create_alerts_for_article_namespace_change
      @articles.each do |article|
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
