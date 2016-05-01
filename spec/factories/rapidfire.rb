FactoryGirl.define do

  factory :matrix_question, class: 'Rapidfire::Question' do
    question_text "Question?"
    association :question_group, factory: :question_group
    type "Rapidfire::Questions::Radio"
    answer_options "option1\r\noption2\r\noption3"
    validation_rules {{
      presence: 0,
      grouped:  1,
      grouped_question:  "What is the question?"
    }}
  end
end
