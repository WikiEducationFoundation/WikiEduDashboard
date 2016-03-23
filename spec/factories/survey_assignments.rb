FactoryGirl.define do
  factory :survey_assignment do
    after(:create) do |sa|
      sa.surveys << create(:survey)
      sa.cohorts << create(:cohort)
    end
  end
end
