# frozen_string_literal: true

# == Schema Information
#
# Table name: surveys
#
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  intro                :text(65535)
#  thanks               :text(65535)
#  open                 :boolean          default(FALSE)
#  closed               :boolean          default(FALSE)
#  confidential_results :boolean          default(FALSE)
#  optout               :text(65535)
#

require 'csv'

# The `open` attr represents a survey that is open for anyone to take it,
# regardless of whether they have a SurveyNotification for it.
# The `closed` attr represents a survey that has finished and is no longer
# available for any users to take it.

# The `confidential_results` attr represents whether a survey is formal research
# that has IRB-imposed data restriction protocols.
# It can be set manually to make the Results page for a survey inaccessible even
# to admins. It also switches to an 'agree/not agree' interface in the survey
# intro, which is assumed to be a consent form.
class Survey < ApplicationRecord
  has_paper_trail
  has_many :survey_assignments, dependent: :destroy
  has_and_belongs_to_many :rapidfire_question_groups,
                          class_name: 'Rapidfire::QuestionGroup',
                          join_table: 'surveys_question_groups',
                          association_foreign_key: 'rapidfire_question_group_id'
  accepts_nested_attributes_for :rapidfire_question_groups

  def status
    return '--' if closed
    active = survey_assignments.map(&:active?)
    return "In Use (#{active.count})" unless active.empty?
    '--'
  end

  def to_csv
    prepare_data_for_csv
    CSV.generate do |csv|
      csv << csv_header
      @users_by_id.each do |id, user|
        response_row = [user.username, course_slug_for_user(id)] + response(user)
        csv << response_row
      end
    end
  end

  private

  # Initializes all data needed for CSV export
  def prepare_data_for_csv
    survey_assignment_ids # Load survey assignments
    survey_responding_users_by_id # Load responding users
    notifications_by_user_id # Load user notifications
    courses_by_id # Load relevant courses
  end

  def csv_header
    question_headers = questions_with_separate_followups.map do |question_hash|
      question = question_hash[:question]
      question_id = question.id
      question_text = question.question_text

      column_name = "Q#{question_id}"
      column_name += '_followup' if question_hash[:followup]
      column_name += ": #{question_text}" unless question_text.empty?
      column_name
    end
    %w[username course] + question_headers
  end

  def response(user)
    answer_group_ids = Rapidfire::AnswerGroup.where(user_id: user.id).pluck(:id)
    questions_with_separate_followups.map do |question_hash|
      answer = Rapidfire::Answer.where(answer_group_id: answer_group_ids,
                                       question_id: question_hash[:question].id).first
      question_hash[:followup] ? answer&.follow_up_answer_text : answer&.answer_text
    end
  end

  # Gets all survey assignment IDs for this survey
  def survey_assignment_ids
    @survey_assignment_ids ||= SurveyAssignment.where(survey_id: id).pluck(:id)
  end

  # Gets users who have responded to this survey, indexed by user ID
  def survey_responding_users_by_id
    user_ids = Rapidfire::AnswerGroup
               .where(question_group_id: rapidfire_question_groups.pluck(:id))
               .pluck(:user_id)
    @users_by_id = User.select(:id, :username).where(id: user_ids).index_by(&:id)
  end

  # Gets the primary survey notification for each user, indexed by user ID
  # Returns a hash structure: { user_id => SurveyNotification object }
  # Example: { 771 => #<SurveyNotification id: 5969, course_id: 10236> }
  # Each notification object contains: id and course_id attributes
  # Only the first (oldest) notification per user is kept if multiple exist
  def notifications_by_user_id
    @notifications_by_user_id ||= SurveyNotification
                                  .joins(:courses_user)
                                  .where(
                                    courses_users: { user_id: @users_by_id.keys },
                                    survey_assignment_id: @survey_assignment_ids
                                  )
                                  .select(
                                    'survey_notifications.id',
                                    'survey_notifications.course_id',
                                    'courses_users.user_id AS user_id'
                                  )
                                  .order('survey_notifications.id')
                                  .group_by(&:user_id)
                                  .transform_values(&:first)
  end

  # Gets courses relevant to survey notifications, indexed by course ID
  def courses_by_id
    @courses_by_id ||= load_courses_by_id(notification_course_ids)
  end

  # Extracts unique course IDs from all survey notifications
  def notification_course_ids
    @notifications_by_user_id.values.map(&:course_id).uniq
  end

  # Loads courses by their IDs and returns them indexed by ID
  def load_courses_by_id(course_ids)
    Course
      .where(id: course_ids)
      .select(:id, :slug)
      .index_by(&:id)
  end

  # Gets the course slug for a specific user from their survey notification
  def course_slug_for_user(user_id)
    # Get the course ID from the user's survey notification
    course_id = @notifications_by_user_id[user_id]&.course_id

    # Return the course slug from cached courses, or fall back to user's latest course
    @courses_by_id[course_id]&.slug || fallback_course_slug_for_user(user_id)&.slug
  end

  # Fallback: gets user's most recent course slug if no notification course exists
  def fallback_course_slug_for_user(user_id)
    Course.joins(:courses_users)
          .where(courses_users: { user_id: })
          .select(:slug)
          .distinct
          .last
  end

  def question_groups_in_order
    @question_groups_in_order ||= SurveysQuestionGroup.where(survey_id: id).order(:position)
                                                      .map(&:rapidfire_question_group)
  end

  def questions_in_order
    @questions_in_order ||= question_groups_in_order.map do |question_group|
      question_group.questions.order(:position)
    end.to_a.flatten
  end

  def questions_with_separate_followups
    return @separated_questions unless @separated_questions.nil?
    @separated_questions = []
    questions_in_order.each do |question|
      @separated_questions << { question:, followup: false }
      next if question.follow_up_question_text.blank?
      @separated_questions << { question:, followup: true }
    end
    @separated_questions
  end
end
