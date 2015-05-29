#= Cohort model
class Cohort < ActiveRecord::Base
  has_many :cohorts_courses, class_name: CohortsCourses
  has_many :courses, through: :cohorts_courses
  has_many :courses_users, through: :courses
  has_many :students, -> { where('courses_users.role = 0').uniq },
           through: :courses_users, source: :user

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
