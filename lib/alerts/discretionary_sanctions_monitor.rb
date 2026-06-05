# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/category_importer"
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

# This class identifies articles that are tagged with discretionary sanctions
# templates, and generates alerts for the articles that have been edited by
# Dashboard participants.
class DiscretionarySanctionsMonitor
  def self.create_alerts_for_course_articles
    new.create_alerts_from_page_titles
  end

  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    find_pages_tagged_for_discretionary_sanctions
    extract_page_titles_from_talk_titles
    normalize_titles
    set_article_ids
  end

  def create_alerts_from_page_titles
    course_articles = ArticlesCourses.where(article_id: @article_ids)
    course_assignments = Assignment.joins(:article)
                                   .where(articles: { title: @page_titles, wiki_id: @wiki.id })
                                   .where(course: Course.current)
    course_articles.each do |articles_course|
      create_edit_alert(articles_course)
    end
    course_assignments.each do |assignments_course|
      create_assignment_alert(assignments_course)
    end
  end

  private

  DS_CATEGORY = 'Category:Wikipedia pages about contentious topics'
  DS_CATEGORY_DEPTH = 1
  def find_pages_tagged_for_discretionary_sanctions
    # These are all talk pages, so the default namespaces for CategoryImporter are fine.
    @ds_talk_titles = CategoryImporter.new(@wiki)
                                      .page_titles_for_category(DS_CATEGORY, DS_CATEGORY_DEPTH)
  end

  def extract_page_titles_from_talk_titles
    @ds_article_titles = @ds_talk_titles.map do |talk_title|
      talk_title[/Talk:(.*)/, 1]
    end
  end

  def normalize_titles
    @page_titles = @ds_article_titles.map do |title|
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
    # Matches CategoryImporter scope and supports index-efficient queries.
    namespace = [Article::Namespaces::MAINSPACE, Article::Namespaces::TALK]
    @article_ids = Article.where(namespace:, wiki_id: @wiki.id, title: @page_titles).pluck(:id)
  end

  def create_edit_alert(articles_course)
    return if unresolved_edit_alert_already_exists?(articles_course)
    return if resolved_edit_alert_covers_latest_revision?(articles_course)
    alert = Alert.create!(type: 'DiscretionarySanctionsEditAlert',
                          article_id: articles_course.article_id,
                          user_id: articles_course&.user_ids&.first,
                          course_id: articles_course.course_id)
    alert.email_content_expert
  end

  def create_assignment_alert(assignments_course)
    return if unresolved_assignment_alert_already_exists?(assignments_course)
    alert = Alert.create!(type: 'DiscretionarySanctionsAssignmentAlert',
                          article_id: assignments_course.article_id,
                          user_id: assignments_course.user_id,
                          course_id: assignments_course.course_id)
    alert.email_content_expert
  end

  def unresolved_edit_alert_already_exists?(articles_course)
    DiscretionarySanctionsEditAlert.exists?(article_id: articles_course.article_id,
                                            course_id: articles_course.course_id,
                                            resolved: false)
  end

  def unresolved_assignment_alert_already_exists?(assignments_course)
    DiscretionarySanctionsAssignmentAlert.exists?(article_id: assignments_course.article_id,
                                                  course_id: assignments_course.course_id,
                                                  resolved: false)
  end

  def resolved_edit_alert_covers_latest_revision?(articles_course)
    last_resolved = DiscretionarySanctionsEditAlert.where(article_id: articles_course.article_id,
                                                          course_id: articles_course.course_id,
                                                          resolved: true).last
    return false unless last_resolved.present?

    course = Course.find(articles_course.course_id)
    # If the last resolved alert was created after the course end, do not create a new one
    return true if last_resolved.created_at > course.end

    mw_page_id = articles_course.article.mw_page_id
    article_content = WikiApi::ArticleContent.new(@wiki)
    !article_content.course_edit_after?(mw_page_id, course:, start_date: last_resolved.created_at)
  end
end
