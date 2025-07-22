# frozen_string_literal: true

FactoryBot.define do
  factory :answer_group, class: 'Rapidfire::AnswerGroup' do
    question_group { FactoryBot.create(:question_group) }
  end
end
