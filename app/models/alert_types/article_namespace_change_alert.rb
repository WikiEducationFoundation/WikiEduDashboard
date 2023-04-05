class ArticleNamespaceChangeAlertManager
    def self.create_alert(article, previous_namespace, new_namespace, course)
      # Create a new alert record of the "Article Namespace Change" type
      alert = Alert.create(type: Alert::ARTICLE_NAMESPACE_CHANGE, course: course, article: article)
  
      # Set the necessary attributes for the alert
      alert.previous_namespace = previous_namespace
      alert.new_namespace = new_namespace
  
      # Save the alert record
      alert.save
  
      # Notify the Wiki Expert for the associated course
      Alert.email_content_expert
    end
  end
  