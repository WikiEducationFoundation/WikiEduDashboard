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

require 'rails_helper'

describe Cohort do
  describe '.initialize_cohorts' do
    it 'create cohorts from application.yml' do
      Cohort.destroy_all
      cohorts = Cohort.all
      expect(cohorts).to be_empty

      Cohort.initialize_cohorts
      cohort = Cohort.first
      expect(cohort.url).to be_a(String)
      expect(cohort.title).to be_a(String)
      expect(cohort.slug).to be_a(String)

      # Make sure it still works if all the cohorts already exist
      Cohort.initialize_cohorts
    end
  end

  describe '.default_cohort' do
    it 'returns a cohort' do
      expect(Cohort.default_cohort).to be_a(Cohort)
    end
  end

  describe 'association' do
    it { should have_many(:question_group_conditionals) }
    it { should have_many(:rapidfire_question_groups).through(:question_group_conditionals) }
  end
end
