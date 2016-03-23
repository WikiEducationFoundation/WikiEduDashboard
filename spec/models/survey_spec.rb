require 'rails_helper'

describe Survey do
  before(:each) do
    @survey = create(:survey)
  end

  it "has and belongs to many QuestionGroups" do
    expect(@survey.rapidfire_question_groups.length).to eq(3)
  end
end
