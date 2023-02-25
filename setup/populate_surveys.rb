# frozen_string_literal: true
ActiveRecord::Base.logger = Logger.new(STDOUT)
def populate_survey_questions
  group = Rapidfire::QuestionGroup.find_or_create_by(
    name: "Populated Survey",
    tags: ""
  )
  Rapidfire::Question.where(question_group_id: group.id).destroy_all
  to_create = []

  1..100.times do |i|
    to_create << {
      question_group_id: group.id, 
      question_text: "Question #{i}", 
      type: "Rapidfire::Questions::Checkbox", 
      position: i,
      answer_options: "A\r\nB\r\nC\r\nD",
      validation_rules: {
        presence: '1',
        grouped: '0',
        grouped_question: '',
        minimum: '',
        maximum: '',
        range_minimum: '',
        range_maximum: '',
        range_increment: '',
        range_divisions: '',
        range_format: '',
        greater_than_or_equal_to: '',
        less_than_or_equal_to: ''
      }
    }
  end
  Rapidfire::Question.insert_all(to_create)
end

def populate_survey_answers
  question_group = Rapidfire::QuestionGroup.find_by(name: "Populated Survey")
  to_delete = []
  Rapidfire::AnswerGroup.where(
    question_group_id: question_group.id,
  ).each do |answer_group|
    Rapidfire::Answer.where(
      answer_group_id: answer_group.id
    ).each do |answer|
      to_delete << answer
    end
  end
  Rapidfire::Answer.delete(to_delete)
  to_create = []
  1..100.times do |round|
    answer_group = Rapidfire::AnswerGroup.create(
      question_group_id: question_group.id,
      user_id: User.first.id,
    )
    Rapidfire::Question.where(
      question_group_id: question_group.id,
    ).each do |question|
      to_create << {
        answer_group_id: answer_group.id,
        question_id: question.id,
        answer_text: ["A","B","C","D"].sample
      }
    end
  end
  Rapidfire::Answer.insert_all(to_create)
end
