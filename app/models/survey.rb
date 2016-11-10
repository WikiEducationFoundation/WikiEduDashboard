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
class Survey < ActiveRecord::Base
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

  CSV_HEADER = [
    'Question Group',
    'Grouped Question',
    'Question Id',
    'Question',
    'Answer',
    'Follow Up Question',
    'Follow Up Answer',
    'User',
    'User Role',
    'Course Slug',
    'Course Campaigns',
    'Course Tags'
  ].freeze

  def to_csv
    CSV.generate do |csv|
      csv << CSV_HEADER
      rapidfire_question_groups.each do |question_group|
        question_group.questions.each do |question|
          question.answers.each do |answer|
            csv << csv_row(question_group, question, answer)
          end
        end
      end
    end
  end

  private

  def csv_row(question_group, question, answer)
    course = answer.course(id)
    course_slug = course.nil? ? nil : course.slug
    campaigns = course.nil? ? nil : course.campaigns.collect(&:title).join(', ')
    tags = course.nil? ? nil : course.tags.collect(&:tag).join(', ')

    [
      question_group.name,
      question.validation_rules[:grouped_question],
      question.id,
      question.question_text,
      answer.answer_text,
      question.follow_up_question_text,
      answer.follow_up_answer_text,
      answer.user.username,
      answer.courses_user_role(id),
      course_slug,
      campaigns,
      tags
    ]
  end
end
