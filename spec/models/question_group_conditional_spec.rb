require 'rails_helper'

RSpec.describe QuestionGroupConditional, type: :model do
  describe 'association' do
    it { should belong_to(:rapidfire_question_group) }
    it { should belong_to(:cohort) }
  end
end
