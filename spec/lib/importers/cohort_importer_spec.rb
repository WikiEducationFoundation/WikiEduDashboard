require 'rails_helper'
require "#{Rails.root}/lib/importers/course_importer"
require "#{Rails.root}/lib/importers/cohort_importer"

describe CohortImporter do
  describe '.update_cohorts' do
    it 'should add and remove courses from cohorts' do
      (1..6).each do |i|
        create(:course, id: i)
      end
      cohort_data = {
        'cohort_1' => [1, 2, 3],
        'cohort_2' => [3, 4, 5]
      }
      CohortImporter.update_cohorts(cohort_data)
      cohort_1 = Cohort.where(slug: 'cohort_1').first
      cohort_2 = Cohort.where(slug: 'cohort_2').first
      expect(cohort_1.courses.all.count).to eq(3)
      expect(cohort_2.courses.all.count).to eq(3)

      cohort_data = {
        'cohort_1' => [1, 2],
        'cohort_2' => [3, 4, 5, 6]
      }
      CohortImporter.update_cohorts(cohort_data)
      expect(cohort_1.courses.all.count).to eq(2)
      expect(cohort_2.courses.all.count).to eq(4)
    end
  end
end
