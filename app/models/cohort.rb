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
  has_many :students, -> { uniq }, through: :courses
  has_many :instructors, -> { uniq }, through: :courses

  ####################
  # Instance methods #
  ####################

  def students_without_instructor_students
    students.where.not(id: instructors.pluck(:id))
  end

  def trained_count
    students_without_instructor_students.trained.count
  end
  #################
  # Class methods #
  #################

  # Create new cohorts from application.yml entries
  def self.initialize_cohorts
    ENV['cohorts'].split(',').each do |cohort|
      next if Cohort.exists?(slug: cohort)
      Cohort.new(
        'title' => cohort.gsub('_', ' ').capitalize,
        'slug' => cohort,
        'url' => ENV['cohort_' + cohort]
      ).save
      Rails.logger.info "Created cohort #{cohort}."
    end
  end
end
