require 'rails_helper'

describe Survey do
  before(:each) do
    @survey = create(:survey)
    @survey.rapidfire_question_groups << create(:question_group)
  end

  it "has and belongs to many QuestionGroups" do
    expect(@survey.rapidfire_question_groups.length).to eq(1)
  end
end
