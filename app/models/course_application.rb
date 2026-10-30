# frozen_string_literal: true
# == Schema Information
#
# Table name: course_applications
#
#  id            :bigint           not null, primary key
#  course_id     :integer          not null
#  user_id       :integer          not null
#  status        :integer          default("submitted"), not null
#  decided_by_id :integer
#  decided_at    :datetime
#  staff_notes   :text(65535)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

# One person's application to one Scholars & Scientists course. The answers are
# Rapidfire answer groups, one per question group on the course's
# CourseApplicationForm, linked back through `course_application_id`.
#
# Statuses are integers so that more (waitlisted, withdrawn) can be added later
# without migrating existing rows.
class CourseApplication < ApplicationRecord
  belongs_to :course
  belongs_to :user
  belongs_to :decided_by, class_name: 'User', optional: true

  # Declared before the answer groups association so it runs first: Rapidfire
  # answer groups don't destroy their own answers.
  before_destroy :delete_answers
  has_many :answer_groups, class_name: 'Rapidfire::AnswerGroup', dependent: :delete_all

  enum :status, { submitted: 0, accepted: 1, declined: 2 }

  validates :user_id, uniqueness: { scope: :course_id }

  private

  def delete_answers
    Rapidfire::Answer.where(answer_group_id: answer_groups.select(:id)).delete_all
  end
end
