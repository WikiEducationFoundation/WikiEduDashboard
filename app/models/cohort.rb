#= Cohort model
class Cohort < ActiveRecord::Base
  has_many :cohorts_courses, class_name: CohortsCourses
  has_many :courses, through: :cohorts_courses
  
  #Create new cohorts from application.yml entries
  def self.initialize_cohorts
    ENV['cohorts'].split(',').each do |cohort|
      unless Cohort.exists?(title: cohort)
        Cohort.new(
          'title' => cohort.gsub('_', ' ').capitalize,
          'slug' => cohort,
          'url' => ENV['cohort_' + cohort]
        ).save
      end
    end
  end
  
end
