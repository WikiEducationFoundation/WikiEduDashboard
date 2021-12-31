# frozen_string_literal: true

# This class to create alerts when a WikiProject Medicine article
# is assigned for a course that doesn't have the medical content
# training module.
# wiki_education mode only
# Goal: to catch cases where a class that wasn't expected 
# to work on medical topics tries to do so.
# Issue #4693
class MedicineArticleMonitor
  WIKI_PROJECT_MEDICINE_CAT = 'Category:All WikiProject Medicine articles'
  NUMBER_OF_ARTICLES_TO_CHECK = 5

  def self.create_alerts_for_no_med_training_for_course
    new.create_alerts_for_no_med_training_for_course
  end

  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
  end

  def create_alerts_for_no_med_training_for_course
    last_assigned_med_articles.each do |assignment|
      unless med_training_for_course?(assignment.course_id)
        create_alert_for_no_med_training_for_course(assignment)
      end
    end
  end

  def create_alert_for_no_med_training_for_course(assignment)
    return if alert_already_exists?(assignment)

    alert = Alert.create!(type: 'NoMedTrainingForCourseAlert',
                  article_id: assignment.article_id,
                  course_id: assignment.course_id)
    alert.email_content_expert
  end

  def alert_already_exists?(assignment)
    Alert.exists?(type: 'NoMedTrainingForCourseAlert',
                  article_id: assignment.article_id,
                  course_id: assignment.course_id)
  end

  def last_assigned_med_articles
    last_assigned_articles
      .select { |assignment| med_article?(assignment.article_title) }
  end

  def last_assigned_articles
    Assignment.last NUMBER_OF_ARTICLES_TO_CHECK
  end

  def med_training_for_course?(course_id)
    if Course
       .find(course_id)
       .training_modules
       .find { |tm| tm.slug == 'editing-medical-topics' }
      true
    else
      false
    end
  end

  # Query
  # curl "https://en.wikipedia.org/w/api.php?action=query
  # &prop=categories&titles=Talk:Appendectomy
  # &cllimit=50&clcategories=Category:All_WikiProject_Medicine_articles
  # &indexpageids=1&format=json"
  # No need to normalize article title
  # "Talk:Colonic polypectomy" eq Talk:Colonic_polypectomy
  def med_article?(title)
    api = WikiApi.new @wiki
    query_params = {
      action: 'query',
      prop: 'categories',
      clcategories: WIKI_PROJECT_MEDICINE_CAT,
      titles: "Talk:#{title}",
      cllimit: 50,
      indexpageids: 1
    }
    body = api.query(query_params)
    id = body.data['pageids'].first
    within_wiki_project_medecine_scope?(body, id)
  end

  def within_wiki_project_medecine_scope?(hash, id)
    hash.data.dig('pages', id, 'categories') ? true : false
  end
end
