module Rapidfire
  module AnswerSpecHelper
    def create_answers
      FactoryGirl.create(:answer, :question => @question_checkbox, :answer_text => 'hindi')
      FactoryGirl.create(:answer, :question => @question_checkbox, :answer_text => "hindi\r\ntelugu")
      FactoryGirl.create(:answer, :question => @question_checkbox, :answer_text => "hindi\r\nkannada")

      FactoryGirl.create(:answer, :question => @question_select, :answer_text => 'mac')
      FactoryGirl.create(:answer, :question => @question_select, :answer_text => 'mac')
      FactoryGirl.create(:answer, :question => @question_select, :answer_text => 'windows')

      FactoryGirl.create(:answer, :question => @question_radio, :answer_text => 'male')
      FactoryGirl.create(:answer, :question => @question_radio, :answer_text => 'female')

      3.times do
        FactoryGirl.create(:answer, :question => @question_date, :answer_text => Date.today.to_s)
        FactoryGirl.create(:answer, :question => @question_long, :answer_text => 'my bio goes on and on!')
        FactoryGirl.create(:answer, :question => @question_numeric, :answer_text => 999)
        FactoryGirl.create(:answer, :question => @question_short, :answer_text => 'this is cool')
      end
    end
  end
end
