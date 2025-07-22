# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/category_importer"

# This class identifies articles involved in deletion processes on
# enabled wikis and creates alerts for them.
# It works by first finding all the article titles, and then matching those
# up with articles edited by students (ie, ArticlesCourses).
class ArticlesForDeletionMonitor
  # To monitor for deletion on a new wiki, we need to know which categories to
  # check for speedy deletion, proposed deletion, and deletion discussions, along
  # with the prefix for deletion discussion pages so that we can extract the
  # article title.
  # This will require adjustment for wikis that don't follow the English Wikipedia
  # deletion process example.
  def self.enable_for(wiki, afd:, afd_prefix:, prod:, speedy:)
    settings_record.value[{ language: wiki.language, project: wiki.project }] =
      { AFD: afd,
        AFD_PREFIX: afd_prefix,
        PROD: prod,
        SPEEDY: speedy }
    settings_record.save
  end

  def self.create_alerts_for_course_articles
    enabled_wikis.each do |wiki_settings|
      new(wiki_settings).create_alerts_from_page_titles
    end
  end

  #################
  # Class helpers #
  #################
  def self.settings_record
    @settings_record ||= Setting.find_or_create_by(key: 'deletion_monitoring')
  end

  def self.enabled_wikis
    settings_record.value.map do |wiki, settings|
      { wiki:, settings: }
    end
  end

  ########################################
  # Alert routine for an individual wiki #
  ########################################

  def initialize(wiki_settings)
    @wiki = Wiki.find_by(wiki_settings[:wiki])
    @settings = wiki_settings[:settings]

    find_deletion_discussions
    extract_page_titles_from_deletion_discussions
    find_proposed_deletions
    find_candidates_for_speedy_deletion
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

  def find_deletion_discussions
    category = @settings[:AFD]
    depth = 2
    namespace = Article::Namespaces::PROJECT
    @afd_titles = CategoryImporter.new(@wiki).page_titles_for_category(category, depth, namespace)
  end

  def find_proposed_deletions
    category = @settings[:PROD]
    depth = 0
    # Proposed deletion category is used for mainspace articles, so the default namespaces work.
    # https://en.wikipedia.org/wiki/Category:Proposed_deletion
    @prod_article_titles = CategoryImporter.new(@wiki).page_titles_for_category(category, depth)
  end

  def find_candidates_for_speedy_deletion
    category = @settings[:SPEEDY]
    # This captures the main CSD categories, but excludes more complicated things
    # that are further down the category tree.
    depth = 1
    # CSD can apply to any namespace, but is mainly relevant for mainspace.
    # Checking only against the default namespaces of main and talk is okay.
    # https://en.wikipedia.org/wiki/Category:Candidates_for_speedy_deletion
    @csd_article_titles = CategoryImporter.new(@wiki).page_titles_for_category(category, depth)
  end

  def extract_page_titles_from_deletion_discussions
    @afd_article_titles = @afd_titles.map do |afd_title|
      afd_title[/#{@settings[:AFD_PREFIX]}(.*)/, 1]
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

  def set_article_ids
    # Use only relevant namespaces:
    # - MAINSPACE: actual articles
    # - TALK: occasionally tagged for deletion
    # - PROJECT: AfD discussion pages (e.g., Wikipedia:Articles_for_deletion/...)
    # Matches CategoryImporter scope and supports index-efficient queries.
    namespace = [Article::Namespaces::MAINSPACE, Article::Namespaces::TALK,
                 Article::Namespaces::PROJECT]
    @article_ids = Article.where(namespace:, title: @page_titles, wiki_id: @wiki.id).pluck(:id)
  end

  def create_alert(articles_course)
    return if alert_already_exists?(articles_course)
    alert = Alert.create!(type: 'ArticlesForDeletionAlert',
                          article_id: articles_course.article_id,
                          user_id: articles_course&.user_ids&.first,
                          course_id: articles_course.course_id)
    alert.email_content_expert
  end

  def alert_already_exists?(articles_course)
    Alert.exists?(article_id: articles_course.article_id,
                  course_id: articles_course.course_id,
                  type: 'ArticlesForDeletionAlert',
                  resolved: false)
  end
end
