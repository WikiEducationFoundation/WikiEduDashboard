# frozen_string_literal: true
# == Schema Information
#
# Table name: course_application_forms
#
#  id                 :bigint           not null, primary key
#  course_id          :integer          not null
#  open               :boolean          default(FALSE), not null
#  intro              :text(65535)
#  question_group_ids :text(65535)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

# The application form for a Scholars & Scientists course (Wiki Education
# Dashboard only). Its questions are Rapidfire question groups, in order: a base
# group shared by every course, then any narrower groups for a course theme or a
# single course. Applications themselves are CourseApplication records.
#
# A group on any course's form is kept out of surveys, so its answers come only
# from applications, and Rapidfire refuses to delete it (see
# config/initializers/surveys.rb).
class CourseApplicationForm < ApplicationRecord
  belongs_to :course

  serialize :question_group_ids, type: Array

  before_validation :normalize_question_group_ids

  validates :course_id, uniqueness: true
  validate :course_takes_applications
  validate :question_groups_exist
  validate :question_groups_outside_surveys
  validate :open_form_has_question_groups

  # Every question group on any course's form. Few forms ever exist, so this
  # reads them all rather than querying a join table.
  def self.question_group_ids_in_use
    pluck(:question_group_ids).flatten.compact.uniq
  end

  def self.uses_question_group?(question_group_id)
    question_group_ids_in_use.include?(question_group_id)
  end

  # The form's Rapidfire question groups, in form order.
  def question_groups
    groups_by_id = Rapidfire::QuestionGroup.where(id: question_group_ids).index_by(&:id)
    question_group_ids.filter_map { |id| groups_by_id[id] }
  end

  private

  # Ids arrive as form params: strings, possibly blank, possibly repeated.
  def normalize_question_group_ids
    self.question_group_ids = Array(question_group_ids).compact_blank.map(&:to_i).uniq
  end

  def course_takes_applications
    return if course.nil? || course.applications_allowed?

    errors.add(:course, 'does not take applications')
  end

  def question_groups_exist
    missing = question_group_ids - Rapidfire::QuestionGroup.where(id: question_group_ids).pluck(:id)
    errors.add(:question_group_ids, "include unknown ids: #{missing.join(', ')}") if missing.any?
  end

  def question_groups_outside_surveys
    in_surveys = SurveysQuestionGroup.where(rapidfire_question_group_id: question_group_ids)
                                     .distinct.pluck(:rapidfire_question_group_id)
    return if in_surveys.empty?

    errors.add(:question_group_ids, "include groups used in surveys: #{in_surveys.join(', ')}")
  end

  def open_form_has_question_groups
    return unless open && question_group_ids.empty?

    errors.add(:base, I18n.t('course_application_forms.no_question_groups_error'))
  end
end
