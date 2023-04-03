# frozen_string_literal: true

require_dependency Rails.root.join('lib/importers/category_importer')

# This class identifies articles that have a high protection level
# that are assigned to students.
class ProtectedArticleMonitor
  def self.create_alerts_for_assigned_articles
    new.create_alerts_from_page_titles
  end

  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    find_protected_articles
    normalize_titles
  end

  def create_alerts_from_page_titles
    course_assignments = Assignment.joins(:article)
                                   .where(articles: { title: @page_titles, wiki_id: @wiki.id })
                                   .where(course: Course.current)

    course_assignments.each do |assignments_course|
      create_assignment_alert(assignments_course)
    end
  end

  private

  FULLY_PROTECTED_CATEGORY = 'Category:Wikipedia fully protected pages'
  XC_CATEGORY = 'Category:Wikipedia extended-confirmed-protected pages'
  def find_protected_articles
    @fp_titles = CategoryImporter.new(@wiki).page_titles_for_category(FULLY_PROTECTED_CATEGORY)
    @xc_titles = CategoryImporter.new(@wiki).page_titles_for_category(XC_CATEGORY)
  end

  def normalize_titles
    @page_titles = (@fp_titles + @xc_titles).map do |title|
      next if title.blank?
      title.tr(' ', '_')
    end
    @page_titles.compact!
    @page_titles.uniq!
  end

  def create_assignment_alert(assignments_course)
    return if alert_already_exists?(assignments_course)
    alert = Alert.create!(type: 'ProtectedArticleAssignmentAlert',
                          article_id: assignments_course.article_id,
                          user_id: assignments_course.user_id,
                          course_id: assignments_course.course_id)
    alert.email_content_expert
  end

  def alert_already_exists?(assignments_course)
    ProtectedArticleAssignmentAlert.exists?(article_id: assignments_course.article_id,
                                            course_id: assignments_course.course_id)
  end
end
