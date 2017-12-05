# frozen_string_literal: true

module Rapidfire
  module QuestionSpecHelper
    def create_questions(question_group)
      @question_checkbox = FactoryBot.create(:q_checkbox, question_group: question_group)
      @question_date = FactoryBot.create(:q_date, question_group: question_group)
      @question_long = FactoryBot.create(:q_long, question_group: question_group)
      @question_numeric = FactoryBot.create(:q_numeric, question_group: question_group)
      @question_radio = FactoryBot.create(:q_radio, question_group: question_group)
      @question_select = FactoryBot.create(:q_select, question_group: question_group)
      @question_short = FactoryBot.create(:q_short, question_group: question_group)
    end
  end
end
