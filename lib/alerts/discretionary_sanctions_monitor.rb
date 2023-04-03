# frozen_string_literal: true

require_dependency Rails.root.join('lib/importers/category_importer')

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
  end

  def create_alerts_from_page_titles
    course_articles = ArticlesCourses.joins(:article)
                                     .where(articles: { title: @page_titles, wiki_id: @wiki.id })
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

  DS_CATEGORY = 'Category:Wikipedia pages under discretionary sanctions'
  DS_CATEGORY_DEPTH = 1
  def find_pages_tagged_for_discretionary_sanctions
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

  def create_edit_alert(articles_course)
    return if unresolved_edit_alert_already_exists?(articles_course)
    revisions = articles_course.course.revisions.where(article_id: articles_course.article_id)
    last_revision = revisions.last
    return if resolved_edit_alert_covers_latest_revision?(articles_course, last_revision)
    first_revision = revisions.first
    alert = Alert.create!(type: 'DiscretionarySanctionsEditAlert',
                          article_id: articles_course.article_id,
                          user_id: first_revision&.user_id,
                          course_id: articles_course.course_id,
                          revision_id: first_revision&.id)
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

  def resolved_edit_alert_covers_latest_revision?(articles_course, last_revision)
    return false if last_revision.nil?
    last_resolved = DiscretionarySanctionsEditAlert.where(article_id: articles_course.article_id,
                                                          course_id: articles_course.course_id,
                                                          resolved: true).last
    return false unless last_resolved.present?
    last_resolved.created_at > last_revision.date
  end
end
