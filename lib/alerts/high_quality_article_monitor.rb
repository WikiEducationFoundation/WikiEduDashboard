# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/category_importer"

# This class identifies articles that are Good or Features
# templates, and generates alerts for the articles that have been edited by
# Dashboard participants.
class HighQualityArticleMonitor
  def self.create_alerts_for_course_articles
    new.create_alerts_from_page_titles
  end

  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    find_good_and_featured_articles
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
    course_assignments.each do |assignment|
      create_assignment_alert(assignment)
    end
  end

  private

  FA_CATEGORY = 'Category:Featured articles'
  GA_CATEGORY = 'Category:Good articles'
  def find_good_and_featured_articles
    @fa_titles = CategoryImporter.new(@wiki).page_titles_for_category(FA_CATEGORY)
    @ga_titles = CategoryImporter.new(@wiki).page_titles_for_category(GA_CATEGORY)
  end

  def normalize_titles
    @page_titles = (@fa_titles + @ga_titles).map do |title|
      next if title.blank?
      title.tr(' ', '_')
    end
    @page_titles.compact!
    @page_titles.uniq!
  end

  def create_edit_alert(articles_course)
    return if unresolved_edit_alert_already_exists?(articles_course)
    return if resolved_alert_covers_latest_revision?(articles_course)
    alert = Alert.create!(type: 'HighQualityArticleEditAlert',
                          article_id: articles_course.article_id,
                          user_id: articles_course&.user_ids&.first,
                          course_id: articles_course.course_id)
    alert.email_content_expert
  end

  def create_assignment_alert(assignment)
    return if unresolved_assignment_alert_already_exists?(assignment)
    alert = Alert.create!(type: 'HighQualityArticleAssignmentAlert',
                          article_id: assignment.article_id,
                          user_id: assignment.user_id,
                          course_id: assignment.course_id)
    alert.email_involved_users
  end

  def unresolved_edit_alert_already_exists?(articles_course)
    HighQualityArticleEditAlert.exists?(article_id: articles_course.article_id,
                                        course_id: articles_course.course_id,
                                        resolved: false)
  end

  def unresolved_assignment_alert_already_exists?(assignments_course)
    HighQualityArticleAssignmentAlert.exists?(article_id: assignments_course.article_id,
                                              course_id: assignments_course.course_id,
                                              resolved: false)
  end

  def resolved_alert_covers_latest_revision?(articles_course)
    last_resolved = HighQualityArticleEditAlert.where(article_id: articles_course.article_id,
                                                      course_id: articles_course.course_id,
                                                      resolved: true).last
    return false unless last_resolved.present?

    course = Course.find(articles_course.course_id)
    # If the last resolved alert was created after the course end, do not create a new one
    return true if last_resolved.created_at > course.end

    mw_page_id = articles_course.article.mw_page_id
    return !course_edit_after?(course, mw_page_id, last_resolved.created_at)
  end

  # Returns true if there was an edit made by a course student to the specified page
  # within the period from the creation date of the last resolved alert to the course end date.
  def course_edit_after?(course, page_id, last_resolved_date)
    @api = WikiApi.new @wiki
    @query_params = query_params(course, page_id, last_resolved_date)
    @continue = true
    until @continue.nil?
      response = @api.query(@query_params)
      return false unless response
      reivisons = filter_revisions(response, page_id, course)
      # If we found an edit made by the user then return true
      return true if reivisons.present?
      @continue = response['continue']
      @query_params['rvcontinue'] = @continue['rvcontinue'] if @continue
    end
    false
  end

  # Filters the API response to exclude edits made by users who are not course students.
  # Returns only the edits associated with the course.
  def filter_revisions(response, page_id, course)
    revisions = response.data['pages'][page_id.to_s]['revisions']
    return if revisions.nil?
    students = course.students.pluck(:username)
    revisions.select { |revision| students.include?(revision['user']) }
  end

  # Queries for edits made to the specified page within the period
  # [last resolved alert, course end]
  def query_params(course, page_id, last_resolved_date)
    {
      action: 'query',
      prop: 'revisions',
      pageids: page_id,
      rvend: last_resolved_date.strftime('%Y%m%d%H%M%S'),
      rvstart: course.end.strftime('%Y%m%d%H%M%S'),
      rvdir: 'older', # List newest first. rvstart has to be later than rvend.
      rvlimit: 500
  }
  end
end
