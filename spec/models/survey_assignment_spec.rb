require 'rails_helper'

RSpec.describe SurveyAssignment, type: :model do
  before(:each) do
    @survey_assignment = create(:survey_assignment)
  end

  it "has one Survey" do
    expect(@survey_assignment.surveys.length).to eq(1)
  end

  it "has one Cohort" do
    expect(@survey_assignment.cohorts.length).to eq(1)
  end

  it "knows about CoursesUsers Roles" do
    expect(CoursesUsers::Roles::INSTRUCTOR_ROLE).to eq(1)
  end

end
