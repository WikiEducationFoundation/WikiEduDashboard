class Features
  def self.disable_onboarding?
    ENV['disable_onboarding'] == 'true'
  end

  def self.disable_help?
    ENV['disable_help'] == 'true'
  end

  def self.disable_training?
    ENV['disable_training'] == 'true'
  end

  def self.disable_wiki_output?
    ENV['disable_wiki_output'] == 'true'
  end

  def self.open_course_creation?
    ENV['open_course_creation'] == 'true'
  end

  def self.enable_legacy_courses?
    ENV['enable_legacy_courses'] == 'true'
  end

  def self.enable_article_finder?
    ENV['enable_article_finder'] == 'true'
  end

  def self.hot_loading?
    ENV['hot_loading'] == 'true'
  end

  def self.email?
    !ENV['SENDER_EMAIL_ADDRESS'].nil?
  end
end
