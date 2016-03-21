FactoryGirl.define do

  factory :matrix_question, class: 'Rapidfire::Question' do
    id 23
    question_text "Question?"
    association :question_group, factory: :question_group
    type "Rapidfire::Questions::Radio"
    position 1
    answer_options "option1\noption2\noption3"
    validation_rules {{
      presence: 1,
      grouped:  1,
      grouped_question:  "What is the question?"
    }}
  end
end
