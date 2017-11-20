# frozen_string_literal: true

FactoryBot.define do
  factory :answer, class: 'Rapidfire::Answer' do
    answer_group  { FactoryBot.create(:answer_group) }
    question      { FactoryBot.create(:q_long)       }
    answer_text   'hello world'
  end
end
