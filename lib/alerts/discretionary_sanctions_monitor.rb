# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/category_importer"

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

  DS_CATEGORY = 'Category:Wikipedia pages about contentious topics'
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
    last_revision_by_student = last_revision(course, mw_page_id, last_resolved.created_at)

    return last_revision_by_student.nil?
  end

  # Returns the most recent edit made by a course student to the specified page,
  # within the period from the creation date of the last resolved alert to the course end date.
  def last_revision(course, page_id, last_resolved_date)
    @api = WikiApi.new @wiki
    @query_params = query_params(course, page_id, last_resolved_date)
    @continue = true
    until @continue.nil?
      response = @api.query(@query_params)
      return unless response
      reivisons = filter_revisions(response, page_id, course)
      # If we found an edit made by the user then return it
      return reivisons.first if reivisons.present?
      @continue = response['continue']
      @query_params['rvcontinue'] = @continue['rvcontinue'] if @continue
    end
    nil
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
      rvmax: 500
  }
  end
end
