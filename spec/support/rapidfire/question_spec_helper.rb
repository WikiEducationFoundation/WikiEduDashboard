module Rapidfire
  module QuestionSpecHelper
    def create_questions(question_group)
      @question_checkbox = FactoryGirl.create(:q_checkbox, :question_group => question_group)
      @question_date = FactoryGirl.create(:q_date, :question_group => question_group)
      @question_long = FactoryGirl.create(:q_long, :question_group => question_group)
      @question_numeric = FactoryGirl.create(:q_numeric, :question_group => question_group)
      @question_radio = FactoryGirl.create(:q_radio, :question_group => question_group)
      @question_select = FactoryGirl.create(:q_select, :question_group => question_group)
      @question_short = FactoryGirl.create(:q_short, :question_group => question_group)
    end
  end
end
