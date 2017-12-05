# frozen_string_literal: true

module Rapidfire
  module AnswerSpecHelper
    def create_answers
      FactoryBot.create(:answer, question: @question_checkbox, answer_text: 'hindi')
      FactoryBot.create(:answer, question: @question_checkbox, answer_text: "hindi\r\ntelugu")
      FactoryBot.create(:answer, question: @question_checkbox, answer_text: "hindi\r\nkannada")

      FactoryBot.create(:answer, question: @question_select, answer_text: 'mac')
      FactoryBot.create(:answer, question: @question_select, answer_text: 'mac')
      FactoryBot.create(:answer, question: @question_select, answer_text: 'windows')

      FactoryBot.create(:answer, question: @question_radio, answer_text: 'male')
      FactoryBot.create(:answer, question: @question_radio, answer_text: 'female')

      3.times do
        FactoryBot.create(:answer, question: @question_date, answer_text: Date.today.to_s)
        FactoryBot.create(:answer, question: @question_long, answer_text: 'my bio goes on and on!')
        FactoryBot.create(:answer, question: @question_numeric, answer_text: 999)
        FactoryBot.create(:answer, question: @question_short, answer_text: 'this is cool')
      end
    end
  end
end
