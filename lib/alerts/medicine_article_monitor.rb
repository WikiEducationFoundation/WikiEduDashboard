# frozen_string_literal: true

# This class to create alerts when a WikiProject Medicine article
# is assigned for a course that doesn't have the medical content
# training module.
# wiki_education mode only
# Goal: to catch cases where a class that wasn't expected
# to work on medical topics tries to do so.
# Issue #4693
class MedicineArticleMonitor
  WIKI_PROJECT_MEDICINE_CAT = 'All_WikiProject_Medicine_pages'
  MEDICAL_TRAINING_IDS = [11, 48].freeze

  def self.create_alerts_for_no_med_training_for_course
    monitor = new
    monitor.refresh_med_article_titles
    monitor.create_alerts_for_no_med_training_for_course
  end

  def initialize
    @assignment_time_for_alert = 1.day.ago
    @assignment_time_for_refresh_titles = 1.day.ago
    @med_category = med_category
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
    Assignment.where('created_at > ?', @assignment_time_for_alert)
  end

  def med_training_for_course?(course_id)
    (Course
      .find(course_id)
      .training_module_ids & MEDICAL_TRAINING_IDS)
      .any?
  end

  def med_article?(title)
    @med_category.article_titles.include? title
  end

  def refresh_med_article_titles
    @med_category.refresh_titles if must_refresh?
  end

  def must_refresh?
    no_article_in_med_category? ||  last_refresh_too_late?
  end

  def last_refresh_too_late?
    @med_category.updated_at < @assignment_time_for_refresh_titles
  end

  def no_article_in_med_category?
    @med_category.article_titles.empty?
  end

  def med_category
    prms = { name: WIKI_PROJECT_MEDICINE_CAT, source: 'category', wiki_id: en_wiki.id }
    Category.find_by(prms) || Category.create(prms)
  end

  def en_wiki
    Wiki.find_by(language: 'en', project: 'wikipedia')
  end
end
