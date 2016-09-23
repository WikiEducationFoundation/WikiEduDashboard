# frozen_string_literal: true
require 'csv'

# == Schema Information
#
# Table name: cohorts
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  slug       :string(255)
#  url        :string(255)
#  created_at :datetime
#  updated_at :datetime
#

#= Cohort model
class Cohort < ActiveRecord::Base
  has_many :cohorts_courses, class_name: CohortsCourses
  has_many :courses, through: :cohorts_courses
  has_many :students, -> { distinct }, through: :courses
  has_many :instructors, -> { distinct }, through: :courses
  has_many :nonstudents, -> { distinct }, through: :courses
  has_and_belongs_to_many :survey_assignments
  has_many :question_group_conditionals
  has_many :rapidfire_question_groups, through: :question_group_conditionals

  ####################
  # Instance methods #
  ####################

  def students_without_nonstudents
    students.where.not(id: nonstudents.pluck(:id))
  end

  def trained_count
    courses.sum(:trained_count)
  end

  def trained_percent
    student_count = students_without_nonstudents.count
    return 100 if student_count.zero?
    100 * trained_count.to_f / student_count
  end

  def users_to_csv(role, opts = {})
    csv_data = []
    courses.each do |course|
      users = course.send(role)
      users.each do |user|
        line = [user.username]
        line << course.slug if opts[:course]
        csv_data << line
      end
    end

    CSV.generate { |csv| csv_data.uniq.each { |line| csv << line } }
  end
  #################
  # Class methods #
  #################

  # Create new cohorts from application.yml entries
  def self.initialize_cohorts
    ENV['cohorts'].split(',').each do |cohort|
      next if Cohort.exists?(slug: cohort)
      Cohort.new(
        'title' => cohort.tr('_', ' ').capitalize,
        'slug' => cohort,
        'url' => ENV['cohort_' + cohort]
      ).save
      Rails.logger.info "Created cohort #{cohort}."
    end
  end

  def self.default_cohort
    find_by(slug: ENV['default_cohort'])
  end
end
