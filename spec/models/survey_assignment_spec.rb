require 'rails_helper'

RSpec.describe SurveyAssignment, type: :model do
  before(:each) do
    @survey = create(:survey)
    @survey_assignment = create(:survey_assignment, :survey_id => @survey.id)
    @survey_assignment.cohorts << create(:cohort)
  end

  it "has one Survey" do
    expect(@survey_assignment.survey).to be_instance_of(Survey)
  end

  it "has one Cohort" do
    expect(@survey_assignment.cohorts.length).to eq(1)
  end

  it "knows about CoursesUsers Roles" do
    expect(CoursesUsers::Roles::INSTRUCTOR_ROLE).to eq(1)
  end

end
