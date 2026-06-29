# frozen_string_literal: true
# == Schema Information
#
# Table name: experiment_courses_users
#
#  id                      :bigint           not null, primary key
#  experiment_slug         :string(255)      not null
#  courses_user_id         :integer          not null
#  status                  :integer          not null
#  userscript_installed_at :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

#= Durable per-student opt-in/opt-out record for an opt-in experiment.
# The absence of a record means the student has not yet responded; once a
# record exists, the course-page invitation is no longer shown. An `opted_in`
# record whose `userscript_installed_at` is nil still has its intervention
# pending (e.g. awaiting OAuth re-authorization).
class ExperimentCoursesUser < ApplicationRecord
  belongs_to :courses_user, class_name: 'CoursesUsers'
  has_one :user, through: :courses_user
  has_one :course, through: :courses_user

  enum :status, { opted_in: 1, opted_out: 2 }

  validates :experiment_slug, presence: true
  validates :courses_user_id, uniqueness: { scope: :experiment_slug }

  scope :for_experiment, ->(slug) { where(experiment_slug: slug) }
end
