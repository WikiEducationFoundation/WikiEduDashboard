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
    CSV.generate do |csv|
      csv << csv_header
      respondents.each do |respondent|
        response_row = [respondent.username, course_slug(respondent)] + response(respondent)
        csv << response_row
      end
    end
  end

  private

  def respondents
    user_ids = Rapidfire::AnswerGroup
               .where(question_group_id: rapidfire_question_groups.pluck(:id))
               .pluck(:user_id)

    @respondents ||= User.where(id: user_ids).includes(survey_notifications: :course)
                         .where(survey_notifications: { survey_assignment_id: survey_assignment_ids }) # rubocop:disable Layout/LineLength
  end

  def survey_assignment_ids
    @survey_assignment_ids ||= survey_assignments.pluck(:id)
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

  def answer_groups_by_user_id
    @answer_groups_by_user_id ||= begin
      user_ids = @respondents.pluck(:id)
      Rapidfire::AnswerGroup
        .where(user_id: user_ids)
        .select(:id, :user_id)
        .group_by(&:user_id)
    end
  end

  def prepare_rapidfire_answers
    @answers ||= begin
      answer_group_ids = answer_groups_by_user_id.values.flatten.map(&:id)
      question_ids = questions_with_separate_followups.map { |q| q[:question].id }

      Rapidfire::Answer.where(
        answer_group_id: answer_group_ids,
        question_id: question_ids
      )
    end

    @answers_by_group_and_question ||= @answers.group_by do |answer|
      [answer.answer_group_id, answer.question_id]
    end
  end

  # This method is intended to be called only through `to_csv`.
  # It relies on `prepare_rapidfire_answers`, which loads data for all respondents
  # ahead of time. Calling `response` independently will not work correctly, as it
  # assumes that this data is already loaded. Do not use this method outside of the
  # `to_csv` flow.
  def response(user) # rubocop:disable Metrics/CyclomaticComplexity
    answer_group_ids = answer_groups_by_user_id[user.id].map(&:id)
    prepare_rapidfire_answers

    questions_with_separate_followups.map do |question_hash|
      question_id = question_hash[:question].id

      answer = answer_group_ids.map do |group_id|
        @answers_by_group_and_question[[group_id, question_id]]&.first
      end.find(&:present?)

      question_hash[:followup] ? answer&.follow_up_answer_text : answer&.answer_text
    end
  end

  def course_slug(user)
    # If there's no course from a notification, fall back to the user's latest course
    user.survey_notifications.first&.course&.slug || user.courses.last&.slug
  end

  def question_groups_in_order
    @question_groups_in_order ||= SurveysQuestionGroup
                                  .includes(rapidfire_question_group: :questions)
                                  .where(survey_id: id)
                                  .order(:position)
                                  .map(&:rapidfire_question_group)
  end

  def questions_in_order
    @questions_in_order ||= question_groups_in_order.map do |question_group|
      question_group.questions.sort_by(&:position)
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
