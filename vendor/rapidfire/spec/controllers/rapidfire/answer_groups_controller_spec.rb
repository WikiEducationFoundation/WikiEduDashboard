require 'spec_helper'

describe Rapidfire::AnswerGroupsController do
  before do
    @routes = Rapidfire::Engine.routes
  end

  # this scenario is possible when there is only 1 radio button question, and
  # user has not selected any option. in this case, browser doesn't send
  # any default value.
  context 'when no parameters are passed' do
    it 'initializes answer builder with empty args' do
      question_group = FactoryGirl.create(:question_group)

      expect {
        post :create, question_group_id: question_group.id
      }.not_to raise_error
    end
  end
end
